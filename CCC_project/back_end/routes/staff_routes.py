from flask import Blueprint, request, jsonify
from ..services.staff_manager import StaffService

staff_bp = Blueprint("staff", __name__)

# GET all staff data 
@staff_bp.get("/staff")
def get_all_staff():
    staff_list = StaffService.get_all_staff()
    return jsonify([s.to_dict() for s in staff_list])

# GET one person from staff data
@staff_bp.get("/staff/<int:id>")
def get_staff(id):
    s = StaffService.get_staff_by_id(id)
    if not s:
        return jsonify({"error": "staff not found"}), 404
    return jsonify(s.to_dict())

# create / reg new staff to staff data base
@staff_bp.post("/staff")
def create_staff():
    data = request.json
    new_s = StaffService.create_staff(data)
    return jsonify(new_s.to_dict()), 201

# changeing/ update to staff database
@staff_bp.put("/staff/<int:id>")
def update_staff(id):
    data = request.json
    updated = StaffService.update_staff(id, data)
    if not updated:
        return jsonify({"error": "staff not found"}), 404
    return jsonify(updated.to_dict())

# DELETE staff data from staff database
@staff_bp.delete("/staff/<int:id>")
def delete_staff(id):
    deleted = StaffService.delete_staff(id)
    if not deleted:
        return jsonify({"error": "staff not found"}), 404
    return jsonify({"message": "deleted"}) , 204
