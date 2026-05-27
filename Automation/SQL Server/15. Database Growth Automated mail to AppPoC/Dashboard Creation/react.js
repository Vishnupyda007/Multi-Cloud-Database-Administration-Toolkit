import React, { useEffect, useState } from 'react';

function App() {
  const [data, setData] = useState([]);

  useEffect(() => {
    fetch('http://localhost:5000/api/growth')
      .then(res => res.json())
      .then(setData);
  }, []);

  return (
    <div>
      <h2>Database Growth Assessment Dashboard</h2>
      <table border="1">
        <thead>
          <tr>
            <th>Server Name</th>
            <th>Database Name</th>
            <th>Total Size (GB)</th>
            <th>Growth (%)</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {data.map((row, idx) => (
            <tr key={idx}>
              <td>{row.ServerName}</td>
              <td>{row.DatabaseName}</td>
              <td>{row.TotalDatabaseSizeGB}</td>
              <td>{row.TotalDataFileSizeGB_PercentChange}</td>
              <td>{row.DatabaseSizeStatus}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default App;