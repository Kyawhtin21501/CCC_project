from flask import Blueprint, request, jsonify
from ..services.staff_manager import StaffService

staff_bp = Blueprint("staff", __name__)

@staff_bp.get("/staff")
def get_all_staff():
    staff_list = StaffService.get_all_staff()
    print("staff routes loaded", staff_list)
    return jsonify([s.to_dict() for s in staff_list])

@staff_bp.get("/staff/<int:staff_id>")
def get_staff(staff_id):
    s = StaffService.get_staff_by_id(staff_id)
    if not s:
        return jsonify({"error": "staff not found"}), 404
    return jsonify(s.to_dict()), 200


@staff_bp.post("/staff")
def create_staff():
    data = request.get_json()
    print("check data " , data)
    if not data:
        return jsonify({"error": "invalid json"}), 400
    
    new_s = StaffService.create_staff(data)
    return jsonify(new_s.to_dict()), 201


@staff_bp.patch("/staff/<int:staff_id>")
def update_staff(staff_id):
    data = request.get_json()
    if not data:
        return jsonify({"error": "invalid json"}), 400
    updated = StaffService.update_staff(staff_id, data)
    if not updated:
        return jsonify({"error": "staff not found"}), 404
    return jsonify(updated.to_dict())

@staff_bp.delete("/staff/<int:staff_id>")
def delete_staff(staff_id):
    deleted = StaffService.delete_staff(staff_id)
    if not deleted:
        return jsonify({"error": "staff not found"}), 404
    return "", 204
