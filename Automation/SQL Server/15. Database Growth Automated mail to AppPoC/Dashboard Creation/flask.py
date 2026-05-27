from flask import Flask, jsonify
import pyodbc

app = Flask(__name__)

@app.route('/api/growth')
def get_growth_data():
    conn = pyodbc.connect('DRIVER={SQL Server};SERVER=CTSINAZSIPDDB06;DATABASE=1CDBAMonitoring;UID=1CDBAMonitor;PWD=1cdbmon@2025#')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM vw_DatabaseGrowthDashboard")
    columns = [column[0] for column in cursor.description]
    results = [dict(zip(columns, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(results)

if __name__ == '__main__':
    app.run(debug=True)