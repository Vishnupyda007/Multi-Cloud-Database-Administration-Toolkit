from flask import Flask, jsonify
import pyodbc
from flask_cors import CORS  # <-- Add this import

app = Flask(__name__)
CORS(app)  # <-- Add this line immediately after app creation

@app.route('/api/growth')
def get_growth_data():
    conn = pyodbc.connect('DRIVER={SQL Server};SERVER=your_server;DATABASE=your_db;UID=your_user;PWD=your_pwd')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM vw_DatabaseGrowthDashboard")
    columns = [column[0] for column in cursor.description]
    results = [dict(zip(columns, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(results)

if __name__ == '__main__':
    app.run(debug=True)