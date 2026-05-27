from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import os

app = Flask(__name__, static_folder="build", static_url_path="")
CORS(app)

@app.route('/api/growth')
def get_growth_data():
    # Hardcoded dummy data for testing: 6 servers, 5 databases each, with all requested columns
    results = [
        # Server 1
        {"ServerName": "TestServer1", "DatabaseName": "TestDB1A", "TotalDatabaseSizeGB": 120, "TotalDataFileSizeGB": 100.0, "TotalDataFileSizeGB_baseline": 85.0, "TotalDataFileSizeChange": 15.0, "PercentageOfTotalGBUsed": 83.0, "TotalDataFileSizeGB_PercentChange": 15.2, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer1", "DatabaseName": "TestDB1B", "TotalDatabaseSizeGB": 110.1, "TotalDataFileSizeGB": 90.0, "TotalDataFileSizeGB_baseline": 82.8, "TotalDataFileSizeChange": 7.2, "PercentageOfTotalGBUsed": 81.7, "TotalDataFileSizeGB_PercentChange": 8.7, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer1", "DatabaseName": "TestDB1C", "TotalDatabaseSizeGB": 95.3, "TotalDataFileSizeGB": 70.0, "TotalDataFileSizeGB_baseline": 71.5, "TotalDataFileSizeChange": -1.5, "PercentageOfTotalGBUsed": 73.5, "TotalDataFileSizeGB_PercentChange": -2.1, "DatabaseSizeStatus": "Decreased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer1", "DatabaseName": "TestDB1D", "TotalDatabaseSizeGB": 102.0, "TotalDataFileSizeGB": 80.0, "TotalDataFileSizeGB_baseline": 80.0, "TotalDataFileSizeChange": 0.0, "PercentageOfTotalGBUsed": 78.4, "TotalDataFileSizeGB_PercentChange": 0.0, "DatabaseSizeStatus": "No Change", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer1", "DatabaseName": "TestDB1E", "TotalDatabaseSizeGB": 88.4, "TotalDataFileSizeGB": 65.0, "TotalDataFileSizeGB_baseline": 62.8, "TotalDataFileSizeChange": 2.2, "PercentageOfTotalGBUsed": 73.5, "TotalDataFileSizeGB_PercentChange": 3.5, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        # Server 2
        {"ServerName": "TestServer2", "DatabaseName": "TestDB2A", "TotalDatabaseSizeGB": 80.3, "TotalDataFileSizeGB": 60.0, "TotalDataFileSizeGB_baseline": 61.2, "TotalDataFileSizeChange": -1.2, "PercentageOfTotalGBUsed": 74.7, "TotalDataFileSizeGB_PercentChange": -2.1, "DatabaseSizeStatus": "Decreased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer2", "DatabaseName": "TestDB2B", "TotalDatabaseSizeGB": 77.8, "TotalDataFileSizeGB": 62.0, "TotalDataFileSizeGB_baseline": 59.0, "TotalDataFileSizeChange": 3.0, "PercentageOfTotalGBUsed": 79.7, "TotalDataFileSizeGB_PercentChange": 5.0, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer2", "DatabaseName": "TestDB2C", "TotalDatabaseSizeGB": 90.0, "TotalDataFileSizeGB": 80.0, "TotalDataFileSizeGB_baseline": 71.2, "TotalDataFileSizeChange": 8.8, "PercentageOfTotalGBUsed": 88.9, "TotalDataFileSizeGB_PercentChange": 12.3, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer2", "DatabaseName": "TestDB2D", "TotalDatabaseSizeGB": 65.2, "TotalDataFileSizeGB": 50.0, "TotalDataFileSizeGB_baseline": 50.0, "TotalDataFileSizeChange": 0.0, "PercentageOfTotalGBUsed": 76.6, "TotalDataFileSizeGB_PercentChange": 0.0, "DatabaseSizeStatus": "No Change", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer2", "DatabaseName": "TestDB2E", "TotalDatabaseSizeGB": 72.5, "TotalDataFileSizeGB": 60.0, "TotalDataFileSizeGB_baseline": 55.6, "TotalDataFileSizeChange": 4.4, "PercentageOfTotalGBUsed": 82.8, "TotalDataFileSizeGB_PercentChange": 7.8, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        # Server 3
        {"ServerName": "TestServer3", "DatabaseName": "TestDB3A", "TotalDatabaseSizeGB": 150.0, "TotalDataFileSizeGB": 120.0, "TotalDataFileSizeGB_baseline": 100.0, "TotalDataFileSizeChange": 20.0, "PercentageOfTotalGBUsed": 80.0, "TotalDataFileSizeGB_PercentChange": 20.0, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer3", "DatabaseName": "TestDB3B", "TotalDatabaseSizeGB": 140.2, "TotalDataFileSizeGB": 110.0, "TotalDataFileSizeGB_baseline": 99.6, "TotalDataFileSizeChange": 10.4, "PercentageOfTotalGBUsed": 78.5, "TotalDataFileSizeGB_PercentChange": 10.5, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer3", "DatabaseName": "TestDB3C", "TotalDatabaseSizeGB": 130.7, "TotalDataFileSizeGB": 90.0, "TotalDataFileSizeGB_baseline": 94.7, "TotalDataFileSizeChange": -4.7, "PercentageOfTotalGBUsed": 68.9, "TotalDataFileSizeGB_PercentChange": -5.0, "DatabaseSizeStatus": "Decreased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer3", "DatabaseName": "TestDB3D", "TotalDatabaseSizeGB": 125.5, "TotalDataFileSizeGB": 100.0, "TotalDataFileSizeGB_baseline": 100.0, "TotalDataFileSizeChange": 0.0, "PercentageOfTotalGBUsed": 79.7, "TotalDataFileSizeGB_PercentChange": 0.0, "DatabaseSizeStatus": "No Change", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer3", "DatabaseName": "TestDB3E", "TotalDatabaseSizeGB": 135.9, "TotalDataFileSizeGB": 110.0, "TotalDataFileSizeGB_baseline": 103.6, "TotalDataFileSizeChange": 6.4, "PercentageOfTotalGBUsed": 80.9, "TotalDataFileSizeGB_PercentChange": 6.2, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        # Server 4
        {"ServerName": "TestServer4", "DatabaseName": "TestDB4A", "TotalDatabaseSizeGB": 60.0, "TotalDataFileSizeGB": 50.0, "TotalDataFileSizeGB_baseline": 48.8, "TotalDataFileSizeChange": 1.2, "PercentageOfTotalGBUsed": 83.3, "TotalDataFileSizeGB_PercentChange": 2.5, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer4", "DatabaseName": "TestDB4B", "TotalDatabaseSizeGB": 55.5, "TotalDataFileSizeGB": 40.0, "TotalDataFileSizeGB_baseline": 40.5, "TotalDataFileSizeChange": -0.5, "PercentageOfTotalGBUsed": 72.1, "TotalDataFileSizeGB_PercentChange": -1.2, "DatabaseSizeStatus": "Decreased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer4", "DatabaseName": "TestDB4C", "TotalDatabaseSizeGB": 70.3, "TotalDataFileSizeGB": 60.0, "TotalDataFileSizeGB_baseline": 55.6, "TotalDataFileSizeChange": 4.4, "PercentageOfTotalGBUsed": 85.4, "TotalDataFileSizeGB_PercentChange": 8.0, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer4", "DatabaseName": "TestDB4D", "TotalDatabaseSizeGB": 65.0, "TotalDataFileSizeGB": 50.0, "TotalDataFileSizeGB_baseline": 50.0, "TotalDataFileSizeChange": 0.0, "PercentageOfTotalGBUsed": 76.9, "TotalDataFileSizeGB_PercentChange": 0.0, "DatabaseSizeStatus": "No Change", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer4", "DatabaseName": "TestDB4E", "TotalDatabaseSizeGB": 68.8, "TotalDataFileSizeGB": 55.0, "TotalDataFileSizeGB_baseline": 52.7, "TotalDataFileSizeChange": 2.3, "PercentageOfTotalGBUsed": 79.9, "TotalDataFileSizeGB_PercentChange": 4.4, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        # Server 5
        {"ServerName": "TestServer5", "DatabaseName": "TestDB5A", "TotalDatabaseSizeGB": 100.0, "TotalDataFileSizeGB": 80.0, "TotalDataFileSizeGB_baseline": 75.0, "TotalDataFileSizeChange": 5.0, "PercentageOfTotalGBUsed": 80.0, "TotalDataFileSizeGB_PercentChange": 6.7, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer5", "DatabaseName": "TestDB5B", "TotalDatabaseSizeGB": 95.0, "TotalDataFileSizeGB": 70.0, "TotalDataFileSizeGB_baseline": 68.0, "TotalDataFileSizeChange": 2.0, "PercentageOfTotalGBUsed": 73.7, "TotalDataFileSizeGB_PercentChange": 2.9, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer5", "DatabaseName": "TestDB5C", "TotalDatabaseSizeGB": 90.0, "TotalDataFileSizeGB": 65.0, "TotalDataFileSizeGB_baseline": 66.0, "TotalDataFileSizeChange": -1.0, "PercentageOfTotalGBUsed": 72.2, "TotalDataFileSizeGB_PercentChange": -1.5, "DatabaseSizeStatus": "Decreased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer5", "DatabaseName": "TestDB5D", "TotalDatabaseSizeGB": 85.0, "TotalDataFileSizeGB": 60.0, "TotalDataFileSizeGB_baseline": 60.0, "TotalDataFileSizeChange": 0.0, "PercentageOfTotalGBUsed": 70.6, "TotalDataFileSizeGB_PercentChange": 0.0, "DatabaseSizeStatus": "No Change", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer5", "DatabaseName": "TestDB5E", "TotalDatabaseSizeGB": 80.0, "TotalDataFileSizeGB": 55.0, "TotalDataFileSizeGB_baseline": 54.0, "TotalDataFileSizeChange": 1.0, "PercentageOfTotalGBUsed": 68.8, "TotalDataFileSizeGB_PercentChange": 1.9, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        # Server 6
        {"ServerName": "TestServer6", "DatabaseName": "TestDB6A", "TotalDatabaseSizeGB": 110.0, "TotalDataFileSizeGB": 90.0, "TotalDataFileSizeGB_baseline": 85.0, "TotalDataFileSizeChange": 5.0, "PercentageOfTotalGBUsed": 81.8, "TotalDataFileSizeGB_PercentChange": 5.9, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer6", "DatabaseName": "TestDB6B", "TotalDatabaseSizeGB": 105.0, "TotalDataFileSizeGB": 85.0, "TotalDataFileSizeGB_baseline": 80.0, "TotalDataFileSizeChange": 5.0, "PercentageOfTotalGBUsed": 81.0, "TotalDataFileSizeGB_PercentChange": 6.3, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer6", "DatabaseName": "TestDB6C", "TotalDatabaseSizeGB": 100.0, "TotalDataFileSizeGB": 80.0, "TotalDataFileSizeGB_baseline": 82.0, "TotalDataFileSizeChange": -2.0, "PercentageOfTotalGBUsed": 80.0, "TotalDataFileSizeGB_PercentChange": -2.4, "DatabaseSizeStatus": "Decreased", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer6", "DatabaseName": "TestDB6D", "TotalDatabaseSizeGB": 95.0, "TotalDataFileSizeGB": 75.0, "TotalDataFileSizeGB_baseline": 75.0, "TotalDataFileSizeChange": 0.0, "PercentageOfTotalGBUsed": 78.9, "TotalDataFileSizeGB_PercentChange": 0.0, "DatabaseSizeStatus": "No Change", "FormattedDate": "2025-08-05"},
        {"ServerName": "TestServer6", "DatabaseName": "TestDB6E", "TotalDatabaseSizeGB": 80.0, "TotalDataFileSizeGB": 70.0, "TotalDataFileSizeGB_baseline": 68.0, "TotalDataFileSizeChange": 2.0, "PercentageOfTotalGBUsed": 77.8, "TotalDataFileSizeGB_PercentChange": 2.9, "DatabaseSizeStatus": "Increased", "FormattedDate": "2025-08-05"},
    ]
    return jsonify(results)

@app.route('/api/top-tables')
def get_top_tables():
    dbname = request.args.get('database')
    # Dummy data for demonstration
    tables = [
        {"TableName": f"Table_{i+1}", "RowCount": 100000*(10-i), "SizeGB": round(5.0*(10-i)/10, 2)}
        for i in range(10)
    ]
    return jsonify(tables)

# Serve React static files
@app.route('/static/<path:path>')
def serve_static(path):
    return send_from_directory(os.path.join(app.static_folder, "static"), path)

# Catch-all route for frontend (React)
@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve_react_app(path):
    if path.startswith("api/"):
        return jsonify({"error": "API endpoint not found"}), 404
    return send_from_directory(app.static_folder, "index.html")

if __name__ == '__main__':
    app.run(debug=True)