from sqlalchemy.orm import Session
from pprint import pprint
import pandas as pd
import numpy as np
from datetime import datetime, timedelta, date

from ortools.sat.python import cp_model

from back_end.models.shift_model import ShiftMain
from back_end.utils.db import get_db
from back_end.services.staff_manager import StaffService
from back_end.services.shift_preferences import ShiftPreferences
from back_end.services.pred_manager import DataPrepare


class ShiftAss:
    def __init__(self):
        self.start_date = "2026-01-01"
        self.end_date = "2026-01-07"

        self.model = cp_model.CpModel()
        self.work = {}
        self.cost = {}
        self.max_cost = {}

    # =========================================================
    # STAFF DATA
    # =========================================================
    def get_staff_data_df(self):
        staff = StaffService.get_all_staff()
        df = pd.DataFrame([s.to_dict() for s in staff])
       
        return df

    # =========================================================
    # SHIFT PREFERENCES
    # =========================================================
    def get_shift_pre_df(self):
        shift_pre = ShiftPreferences.get_shift_pre()
        df = pd.DataFrame([s.to_dict() for s in shift_pre])

        df["date"] = pd.to_datetime(df["date"])
        df = df[
            (df["date"] >= pd.to_datetime(self.start_date)) &
            (df["date"] <= pd.to_datetime(self.end_date))
        ]

        df = df.rename(columns={"staff_id": "id"})
        return df

    # =========================================================
    # PREDICTED SALES
    # =========================================================
    def get_pred_sale(self):
        pred = DataPrepare(self.start_date, self.end_date)
        df = pd.DataFrame(pred.run_prediction())
        df["date"] = pd.to_datetime(df["date"])
        return df

    # =========================================================
    # HELPERS
    # =========================================================
    def pred_sales_per_hour(self, hour, sales):
        if hour in [9, 10]:
            return sales * 0.052
        elif hour in [12, 13, 14, 15]:
            return sales * 0.1
        elif hour in [16, 17, 23]:
            return sales * 0.07
        elif hour in [18, 19, 20]:
            return sales * 0.08
        else:
            return sales * 0.09

    def salary(self, level):
        if level in [1, 2]:
            return 1300
        elif level == 3:
            return 1350
        elif level == 4:
            return 1400
        else:
            return 1500

    # =========================================================
    # COMBINE DATA
    # =========================================================
    def combine_data(self):
        df = pd.merge(
            self.get_shift_pre_df(),
            self.get_staff_data_df(),
            how="left",
            on="id"
        )

        df = pd.merge(
            df,
            self.get_pred_sale(),
            how="left",
            on="date"
        )

        # NaN cleanup
        df["name"] = df["name"].fillna("unknown")
        df["level"] = df["level"].fillna(0).astype(int)
        df["status"] = df["status"].fillna("unknown")
        df["predicted_sales"] = df["predicted_sales"].fillna(0)

        records = []
        for _, row in df.iterrows():
            for h in range(9, 25):
                records.append({
                    "date": row["date"],
                    "hour": h,
                    "id": row["id"],
                    "name": row["name"],
                    "level": row["level"],
                    "status": row["status"],
                    "predicted_sales": row["predicted_sales"],
                })
        unique_dates = df["date"].unique()
        for d in unique_dates:
            pred_val = df[df["date"] == d]["predicted_sales"].values[0] if not df[df["date"] == d].empty else 0
            for h in range(9, 25):
                records.append({
                    "date": d, "hour": h, "id": 1500,
                    "name": "not_enough", "level": 0, "salary": 0, 
                    "predicted_sales": pred_val
                })
        final_df = pd.DataFrame(records)

        final_df["pred_sale_per_hour"] = final_df.apply(
            lambda r: self.pred_sales_per_hour(r["hour"], r["predicted_sales"]),
            axis=1
        )
        """
        final_df["max_cost"] = (
            final_df["pred_sale_per_hour"] * 0.3
        ).astype(int)
        """
        final_df["salary"] = final_df["level"].apply(self.salary).astype(int)

        final_df = final_df.sort_values(
            by=["date", "hour", "id"]
        ).reset_index(drop=True)

        return final_df

    # =========================================================
    # CREATE SHIFT (CP-SAT)
    # =========================================================
    def create_shift(self, df=None):
        model = cp_model.CpModel()
        if df is None:
            df = self.combine_data()
        help_id = 1500
        
        # 決定変数の作成
        work = {}
        for _, row in df.iterrows():
            s, d, h = row["id"], row["date"], row["hour"]
            work[s, d, h] = model.NewBoolVar(f"work_{s}_{d}_{h}")

        # スタッフの属性（レベル・ステータス）を整理
        # 重複を排除してスタッフごとの属性辞書を作成
        staff_info = df.drop_duplicates('id').set_index('id')[['level', 'status']].to_dict('index')
        staff_ids = df["id"].unique()
        dates = df["date"].unique()

        # --- A. 各時間帯の制約 (売上・人数・スキル) ---
        for (d, h), group in df.groupby(["date", "hour"]):
            sales = group["pred_sale_per_hour"].iloc[0]
            
            # 1. 目標人数の確保
            num_staff = max(1, int(sales // 5000))
            slot_vars = [work[row["id"], d, h] for _, row in group.iterrows()]
            model.Add(sum(slot_vars) == num_staff) 

            # 2. 責任者(L4以上 or Help) 必須
            leader_vars = [work[row["id"], d, h] for _, row in group.iterrows() 
                           if staff_info.get(row["id"], {}).get('level', 0) >= 3 or row["id"] == help_id]
            if leader_vars:
                model.Add(sum(leader_vars) >= 1)

        # --- B. 勤務の制約 (個別ルール) ---
        for s in staff_ids:
            if s == help_id: 
                continue 
            
            status = staff_info[s]

            # 1. 【留学生ルール】 週28時間を絶対に超えない
            if status == "international":
                weekly_vars = [work[sid, d, h] for (sid, d, h) in work.keys() if sid == s]
                model.Add(sum(weekly_vars) <= 28)

            for d in dates:
                for h in range(9, 25):
                    if (s, d, h) not in work: continue

                    # 2. 【高校生ルール】 22時以降の勤務禁止 (22時, 23時, 24時は 0 固定)
                    if status == "high_school" and h >= 22:
                        model.Add(work[s, d, h] == 0)

                    # 3. 【最低3時間勤務】 出勤開始後の連続性
                    start_working = model.NewBoolVar(f'start_{s}_{d}_{h}')
                    w_curr = work[s, d, h]
                    w_prev = work[s, d, h-1] if (s, d, h-1) in work else 0
                    model.Add(start_working >= w_curr - w_prev)
                    
                    if (s, d, h+1) in work:
                        model.Add(work[s, d, h+1] >= start_working)
                    if (s, d, h+2) in work:
                        model.Add(work[s, d, h+2] >= start_working)
                    
                    # 4. 【連続勤務制限】 6時間枠で最大5時間まで (休憩)
                    window_6h = [work[s, d, h + i] for i in range(6) if (s, d, h + i) in work]
                    if len(window_6h) == 6:
                        model.Add(sum(window_6h) <= 5)

        # --- C. 目的関数 ---
        obj_terms = []
        for (s, d, h), w in work.items():
            if s == help_id:
                obj_terms.append(w * 100000)
            else:
                sal = df[(df['id'] == s) & (df['hour'] == h)]['salary'].iloc[0]
                obj_terms.append(w * sal)

        model.Minimize(sum(obj_terms))

        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = 10
        status = solver.Solve(model)
        return solver, status, work
        
    def run_test(self):
    # 1. データの準備と計算
        df = self.combine_data()
        solver, status, work = self.create_shift()

        if status not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
            print("❌ 解が見つかりませんでした。制約が厳しすぎる可能性があります。")
            return

    # 2. 結果をリストにまとめる
        results = []
        for (s, d, h), w in work.items():
            if solver.Value(w) == 1:
            # スタッフ名を取得（dfから検索）
                name = df[df["id"] == s]["name"].iloc[0]
                results.append({"date": d, "hour": h, "name": name, "id": s})

        test_df = pd.DataFrame(results).sort_values(["date", "hour"])

    # 3. 見やすく表示
        print("\n--- 🏁 シフト作成結果 (テスト出力) ---")
        for (d, h), group in test_df.groupby(["date", "hour"]):
            names = group["name"].tolist()
        
        # Help(not_enough) が含まれているかチェック
            alert = "⚠️ [HELP発生!]" if "not_enough" in names else "✅ OK"
        
            print(f"{d} {h:02d}時: {alert} | スタッフ: {', '.join(names)}")
    
        print("------------------------------------\n")
        return test_df
        
    def run(self):
        df = self.combine_data()
        solver, status, work = self.create_shift(df)

        shift_ass = []  

        if status in (cp_model.OPTIMAL, cp_model.FEASIBLE):
            for (s, d, h), w in work.items():
                if solver.Value(w) == 1:
                    shift_ass.append({
                        "id": s,
                        "date": d,
                        "hour": h
                    })

            shift_ass_df = pd.DataFrame(shift_ass)


            
        return shift_ass_df


if __name__ == "__main__":
    sa = ShiftAss()
    df= sa.combine_data()
    df2 = sa.run_test()
    df3 = sa.run()
    #print(df.to_string())
    print(df2.head(50))
    print(df3.to_string())

    
    
    
