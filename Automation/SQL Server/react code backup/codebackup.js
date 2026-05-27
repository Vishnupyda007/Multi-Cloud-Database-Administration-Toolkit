import React, { useEffect, useState } from 'react';
import { Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

function App() {
  const [data, setData] = useState([]);
  const [selectedServer, setSelectedServer] = useState('');
  const [serverSearch, setServerSearch] = useState('');
  const [loading, setLoading] = useState(false);

  const fontStack = "'Inter', 'Segoe UI', 'Roboto', 'Arial', 'Helvetica Neue', sans-serif";

  const fetchData = () => {
    setLoading(true);
    fetch('http://localhost:5000/api/growth')
      .then(res => res.json())
      .then(setData)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchData();
  }, []);

  const serverNames = Array.from(new Set(data.map(row => row.ServerName)));
  const filteredServerNames = serverNames.filter(server =>
    server.toLowerCase().includes(serverSearch.toLowerCase()) ||
    data.some(row =>
      row.ServerName === server &&
      row.DatabaseName.toLowerCase().includes(serverSearch.toLowerCase())
    )
  );

  const filteredData = data.filter(row => {
    const matchesServer = selectedServer ? row.ServerName === selectedServer : true;
    const matchesSearch =
      serverSearch.trim() === '' ||
      row.ServerName.toLowerCase().includes(serverSearch.toLowerCase()) ||
      row.DatabaseName.toLowerCase().includes(serverSearch.toLowerCase());
    return matchesServer && matchesSearch;
  });

  // Fluid and cool bar colors
  const getBarColor = (status, type) => {
    if (type === 'TotalDataFileSizeGB') return 'rgba(52, 152, 219, 0.85)'; // blue
    if (type === 'BaselineDataFileSizeGB') return 'rgba(241, 196, 15, 0.85)'; // yellow
    if (type === 'DataFileSizeChange') return status === 'Increased' ? 'rgba(231,76,60,0.85)' : 'rgba(39,174,96,0.85)';
    if (type === 'PercentChange') {
      if (status === 'Increased') return 'rgba(139,0,0,0.95)'; // dark red
      return 'rgba(0,100,0,0.95)'; // dark green
    }
    return 'rgba(44,62,80,0.7)';
  };

  // Chart options for more fluid and cool look
  const getChartOptions = (dbName) => ({
    responsive: true,
    indexAxis: 'y', // <-- This makes the bar chart horizontal
    plugins: {
      legend: { display: false },
      title: {
        display: true,
        text: `Growth Metrics for ${dbName}`,
        font: { size: 18, family: fontStack, weight: 'bold' },
        color: '#2980b9',
        padding: { top: 10, bottom: 20 }
      },
      tooltip: {
        backgroundColor: '#23272f',
        titleColor: '#fff',
        bodyColor: '#fff',
        borderColor: '#2980b9',
        borderWidth: 2,
        padding: 12,
        cornerRadius: 8
      }
    },
    layout: {
      padding: { left: 10, right: 10, top: 10, bottom: 10 }
    },
    scales: {
      x: {
        beginAtZero: true,
        grid: { color: 'rgba(44,62,80,0.08)' },
        ticks: { font: { size: 14, family: fontStack }, color: '#2c3e50' }
      },
      y: {
        grid: { display: false },
        ticks: { font: { size: 15, family: fontStack, weight: 'bold' }, color: '#2c3e50' }
      }
    },
    animation: {
      duration: 1200,
      easing: 'easeOutElastic'
    }
  });

  return (
    <div style={{
      fontFamily: fontStack,
      padding: '32px',
      background: 'linear-gradient(135deg, #e0eafc 0%, #cfdef3 100%)',
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center'
    }}>
      <div style={{
        maxWidth: '1100px',
        width: '100%',
        background: '#fff',
        borderRadius: '18px',
        boxShadow: '0 6px 24px rgba(44,62,80,0.10)',
        padding: '32px 40px',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        fontFamily: fontStack
      }}>
        <h2 style={{
          color: '#2c3e50',
          marginBottom: '18px',
          fontWeight: 700,
          letterSpacing: '0.5px',
          textAlign: 'center',
          fontFamily: fontStack
        }}>
          Database Growth Assessment Dashboard
        </h2>
        {/* Baseline Date Info */}
        <div style={{
          marginBottom: '18px',
          width: '100%',
          textAlign: 'center',
          fontSize: '16px',
          color: '#34495e',
          fontWeight: 500,
          background: 'linear-gradient(90deg, #e0eafc 0%, #f7f9fa 100%)',
          borderRadius: '8px',
          padding: '10px 0'
        }}>
          <span style={{ color: '#2980b9', fontWeight: 600 }}>Baseline Date:</span> 25th May 2025
        </div>
        <div style={{
          marginBottom: '18px',
          display: 'flex',
          alignItems: 'center',
          gap: '16px',
          justifyContent: 'center',
          width: '100%',
          fontFamily: fontStack
        }}>
          <label htmlFor="serverDropdown" style={{
            fontWeight: 600,
            fontSize: '18px',
            fontFamily: fontStack
          }}>
            Search Server / Database:
          </label>
          <div style={{
            display: 'flex',
            flexDirection: 'row',
            flex: 1,
            maxWidth: '400px',
            gap: '12px',
            fontFamily: fontStack
          }}>
            <input
              type="text"
              placeholder="Type Server or Database Name..."
              value={serverSearch}
              onChange={e => setServerSearch(e.target.value)}
              style={{
                flex: 2,
                padding: '10px 16px',
                borderRadius: '8px',
                border: '1px solid #bfc9d1',
                fontSize: '17px',
                background: '#f7f9fa',
                transition: 'box-shadow 0.2s',
                boxShadow: '0 2px 8px rgba(44,62,80,0.08)',
                outline: 'none',
                fontFamily: fontStack,
                fontWeight: 500
              }}
              onFocus={e => e.target.style.boxShadow = '0 0 0 2px #6dd5fa'}
              onBlur={e => e.target.style.boxShadow = '0 2px 8px rgba(44,62,80,0.08)'}
            />
            <select
              id="serverDropdown"
              value={selectedServer}
              onChange={e => setSelectedServer(e.target.value)}
              style={{
                flex: 1,
                padding: '10px 16px',
                borderRadius: '8px',
                border: '1px solid #bfc9d1',
                fontSize: '17px',
                background: '#f7f9fa',
                boxShadow: '0 2px 8px rgba(44,62,80,0.08)',
                transition: 'box-shadow 0.2s',
                outline: 'none',
                fontFamily: fontStack,
                fontWeight: 500,
                cursor: 'pointer'
              }}
              onFocus={e => e.target.style.boxShadow = '0 0 0 2px #2980b9'}
              onBlur={e => e.target.style.boxShadow = '0 2px 8px rgba(44,62,80,0.08)'}
            >
              <option value="">All Servers</option>
              {filteredServerNames.map(server => (
                <option key={server} value={server}>
                  {server}
                </option>
              ))}
            </select>
            <button
              onClick={fetchData}
              disabled={loading}
              style={{
                marginLeft: '8px',
                padding: '10px 18px',
                borderRadius: '8px',
                border: 'none',
                background: '#2980b9',
                color: '#fff',
                fontWeight: 600,
                fontSize: '16px',
                cursor: loading ? 'not-allowed' : 'pointer',
                boxShadow: '0 2px 8px rgba(44,62,80,0.08)',
                fontFamily: fontStack,
                transition: 'background 0.2s'
              }}
            >
              {loading ? 'Refreshing...' : 'Sync'}
            </button>
          </div>
        </div>
        <div style={{ overflowX: 'auto', width: '100%', display: 'flex', justifyContent: 'center', fontFamily: fontStack }}>
          <table style={{
            borderCollapse: 'separate',
            borderSpacing: '0',
            width: '100%',
            background: '#fff',
            borderRadius: '12px',
            boxShadow: '0 2px 8px rgba(44,62,80,0.08)',
            textAlign: 'center',
            fontFamily: fontStack
          }}>
            <thead>
              <tr style={{
                background: 'linear-gradient(90deg, #2980b9 0%, #6dd5fa 100%)',
                color: '#fff',
                fontFamily: fontStack
              }}>
                {[
                  "Server Name",
                  "Database Name",
                  "Total DB Size (GB)",
                  "Total DataFile Size (GB)",
                  "Baseline DataFile Size (GB)",
                  "DataFile Size Change (GB)",
                  "% of Total GB Used",
                  "Percent Change",
                  "Status",
                  "Date"
                ].map((col, idx) => (
                  <th
                    key={col}
                    style={{
                      padding: '14px',
                      border: 'none',
                      fontSize: '16px',
                      borderTopLeftRadius: idx === 0 ? '12px' : '0',
                      borderTopRightRadius: idx === 9 ? '12px' : '0',
                      fontWeight: 600,
                      fontFamily: fontStack
                    }}
                  >
                    {col}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filteredData.length === 0 ? (
                <tr>
                  <td colSpan={10} style={{
                    textAlign: 'center',
                    padding: '24px',
                    color: '#888',
                    fontSize: '18px',
                    fontFamily: fontStack
                  }}>
                    No data available for the selected server.
                  </td>
                </tr>
              ) : (
                filteredData.map((row, idx) => (
                  <React.Fragment key={idx}>
                    <tr style={{
                      background: idx % 2 === 0 ? '#f2f6fa' : '#fff',
                      transition: 'background 0.3s',
                      fontFamily: fontStack
                    }}>
                      <td style={{ padding: '12px', fontFamily: fontStack }}>{row.ServerName}</td>
                      <td style={{ padding: '12px', fontFamily: fontStack }}>{row.DatabaseName}</td>
                      <td style={{ padding: '12px', fontFamily: fontStack }}>{row.TotalDatabaseSizeGB}</td>
                      <td style={{ padding: '12px', fontFamily: fontStack }}>{row.TotalDataFileSizeGB}</td>
                      <td style={{ padding: '12px', fontFamily: fontStack }}>{row.TotalDataFileSizeGB_baseline}</td>
                      <td style={{ padding: '12px', fontFamily: fontStack }}>{row.TotalDataFileSizeChange}</td>
                      <td style={{ padding: '12px', fontFamily: fontStack }}>{row.PercentageOfTotalGBUsed}</td>
                      <td style={{ padding: '12px', fontFamily: fontStack }}>{row.TotalDataFileSizeGB_PercentChange}</td>
                      <td style={{
                        padding: '12px',
                        color: row.DatabaseSizeStatus === 'Increased'
                          ? '#e74c3c'
                          : '#27ae60',
                        fontWeight: 'bold',
                        whiteSpace: 'nowrap',
                        fontFamily: fontStack
                      }}>
                        {row.DatabaseSizeStatus}
                      </td>
                      <td style={{ padding: '12px', whiteSpace: 'nowrap', fontFamily: fontStack }}>{row.FormattedDate}</td>
                    </tr>
                    <tr>
                      <td colSpan={10} style={{ padding: '16px 0', background: '#f7f9fa' }}>
                        <div style={{
                          maxWidth: 650,
                          margin: '0 auto',
                          borderRadius: '16px',
                          boxShadow: '0 4px 24px rgba(44,62,80,0.10)',
                          background: 'linear-gradient(135deg, #e0eafc 0%, #f7f9fa 100%)',
                          padding: '24px 18px'
                        }}>
                          <Bar
                            data={{
                              labels: [
                                'Total DataFile Size (GB)',
                                'Baseline DataFile Size (GB)',
                                'DataFile Size Change (GB)',
                                'Percent Change'
                              ],
                              datasets: [
                                {
                                  label: row.DatabaseName,
                                  data: [
                                    row.TotalDataFileSizeGB,
                                    row.TotalDataFileSizeGB_baseline,
                                    row.TotalDataFileSizeChange,
                                    row.TotalDataFileSizeGB_PercentChange
                                  ],
                                  backgroundColor: [
                                    getBarColor(row.DatabaseSizeStatus, 'TotalDataFileSizeGB'),
                                    getBarColor(row.DatabaseSizeStatus, 'BaselineDataFileSizeGB'),
                                    getBarColor(row.DatabaseSizeStatus, 'DataFileSizeChange'),
                                    getBarColor(row.DatabaseSizeStatus, 'PercentChange')
                                  ],
                                  borderRadius: 12,
                                  borderSkipped: false,
                                  hoverBackgroundColor: [
                                    'rgba(52, 152, 219, 1)',
                                    'rgba(241, 196, 15, 1)',
                                    row.DatabaseSizeStatus === 'Increased' ? 'rgba(231,76,60,1)' : 'rgba(39,174,96,1)',
                                    row.DatabaseSizeStatus === 'Increased' ? 'rgba(139,0,0,1)' : 'rgba(0,100,0,1)'
                                  ]
                                }
                              ]
                            }}
                            options={getChartOptions(row.DatabaseName)}
                          />
                        </div>
                      </td>
                    </tr>
                  </React.Fragment>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

export default App;