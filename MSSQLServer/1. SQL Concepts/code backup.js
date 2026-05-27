import React, { useEffect, useState, useCallback } from 'react';
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
import * as XLSX from 'xlsx';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

function App() {
  const [data, setData] = useState([]);
  const [selectedServer, setSelectedServer] = useState('');
  const [serverSearch, setServerSearch] = useState('');
  const [loading, setLoading] = useState(false);
  const [expandedDb, setExpandedDb] = useState(null);
  const [topTables, setTopTables] = useState({});
  const [sortOrder, setSortOrder] = useState('default'); // 'default', 'desc', or 'asc'
  const [sortField, setSortField] = useState('percentChange'); // 'percentChange' or 'totalDbSize'

  const fontStack = "'Inter', 'Segoe UI', 'Roboto', 'Arial', 'Helvetica Neue', sans-serif";

  const fetchData = () => {
    setLoading(true);
    fetch('https://cts-vibeappca5204-3.azurewebsites.net/api/growth')
      .then(res => res.json())
      .then(setData)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchData();
  }, []);

  const fetchTopTables = useCallback(async (dbName) => {
    const res = await fetch(`https://cts-vibeappca5204-3.azurewebsites.net/api/top-tables?database=${encodeURIComponent(dbName)}`);
    const tables = await res.json();
    setTopTables(prev => ({ ...prev, [dbName]: tables }));
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

  // Sorting logic for databases by selected field and order
  const sortedFilteredData = sortOrder === 'default'
    ? filteredData
    : [...filteredData].sort((a, b) => {
        let aVal, bVal;
        if (sortField === 'totalDbSize') {
          aVal = parseFloat(a.TotalDatabaseSizeGB) || 0;
          bVal = parseFloat(b.TotalDatabaseSizeGB) || 0;
        } else {
          aVal = parseFloat(a.TotalDataFileSizeGB_PercentChange) || 0;
          bVal = parseFloat(b.TotalDataFileSizeGB_PercentChange) || 0;
        }
        return sortOrder === 'desc' ? bVal - aVal : aVal - bVal;
      });

  // Fluid and cool bar colors
  // Update getBarColor and getBarHoverColor for violet
  const getBarColor = (status, type) => {
    if (type === 'TotalDataFileSizeGB') return 'rgba(254,1,154, 0.85)'; // violet
    if (type === 'BaselineDataFileSizeGB') return 'rgba(241, 196, 15, 0.85)'; // yellow
    if (type === 'DataFileSizeChange') return status === 'Increased' ? 'rgba(231,76,60,0.85)' : 'rgba(39,174,96,0.85)';
    if (type === 'PercentChange') {
      if (status === 'Increased') return 'rgba(255, 0, 0, 0.85)'; // bright red
      return 'rgba(46, 204, 113, 0.85)'; // bright green
    }
    return 'rgba(44,62,80,0.7)';
  };

  const getBarHoverColor = (status, type) => {
    if (type === 'TotalDataFileSizeGB') return 'rgba(254,1,154, 1)'; // violet
    if (type === 'BaselineDataFileSizeGB') return 'rgba(241, 196, 15, 1)'; // yellow
    if (type === 'DataFileSizeChange') return status === 'Increased' ? 'rgba(231,76,60,1)' : 'rgba(39,174,96,1)';
    if (type === 'PercentChange') {
      if (status === 'Increased') return 'rgba(255, 0, 0, 1)'; // bright red
      return 'rgba(46, 204, 113, 1)'; // bright green
    }
    return 'rgba(44,62,80,1)';
  };

  // Chart options for more fluid and cool look
  const getChartOptions = (dbName) => ({
    responsive: true,
    indexAxis: 'y', // Horizontal bar chart
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
        ticks: { font: { size: 14, family: fontStack }, color: '#f7f9fa' },
        title: {
          display: true,
          text: 'Value',
          color: '#f7f9fa',
          font: { size: 15, family: fontStack, weight: 'bold' },
          padding: { top: 8 }
        }
      },
      y: {
        grid: { display: false },
        ticks: { font: { size: 15, family: fontStack, weight: 'bold' }, color: '#f7f9fa' },
        title: {
          display: true,
          text: 'Metric',
          color: '#f7f9fa',
          font: { size: 15, family: fontStack, weight: 'bold' },
          padding: { right: 8 }
        }
      }
    },
    animation: {
      duration: 1200,
      easing: 'easeOutElastic'
    }
  });

  // Export to Excel handler
  const handleExportExcel = () => {
    // Prepare data for export (use sortedFilteredData for current view)
    const exportData = sortedFilteredData.map(row => ({
      "Server Name": row.ServerName,
      "Database Name": row.DatabaseName,
      "Total DB Size (GB)": row.TotalDatabaseSizeGB,
      "Present DataFile Size (GB)": row.TotalDataFileSizeGB,
      "Baseline DataFile Size (GB)": row.TotalDataFileSizeGB_baseline,
      "DataFile Size Change (GB)": row.TotalDataFileSizeChange,
      "% of Total GB Used": row.PercentageOfTotalGBUsed,
      "Percent Change": row.TotalDataFileSizeGB_PercentChange,
      "Status": row.DatabaseSizeStatus,
      "Date": row.FormattedDate
    }));
    const ws = XLSX.utils.json_to_sheet(exportData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "DatabaseGrowth");
    XLSX.writeFile(wb, "1C_Applications_Database_Growth.xlsx");
  };

  return (
    <div style={{
      fontFamily: fontStack,
      padding: '32px',
      background: 'linear-gradient(135deg, #e3e6f3 0%, #f6f7fb 100%)',
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center'
    }}>
      <div style={{
        maxWidth: '1150px',
        width: '100%',
        background: 'linear-gradient(120deg, #f7f9fa 0%, #e3e6f3 100%)', // Subtle, professional gradient
        borderRadius: '18px',
        boxShadow: '0 8px 32px rgba(136,84,208,0.10), 0 1.5px 8px rgba(52, 152, 219, 0.08)',
        padding: '28px 28px 36px 28px',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        fontFamily: fontStack
      }}>
        <h2 style={{
          color: '#6c47c7',
          marginBottom: '8px',
          fontWeight: 800,
          letterSpacing: '0.5px',
          textAlign: 'center',
          fontFamily: fontStack,
          fontSize: '2rem',
          lineHeight: 1.2,
          padding: '0 0 4px 0'
          //fontFamily: "'Inter', 'Segoe UI', 'Roboto', 'Arial', 'Helvetica Neue', sans-serif"
        }}>
          1C Applications Database Growth Assessment Tool
        </h2>
        {/* Baseline Date Info */}
        <div style={{
          marginBottom: '18px',
          width: '100%',
          textAlign: 'center',
          fontSize: '16px',
          color: '#6c47c7',
          fontWeight: 500,
          background: 'linear-gradient(90deg, #e3e6f3 0%, #f6f7fb 100%)',
          borderRadius: '8px',
          padding: '10px 0'
        }}>
          <span style={{ color: '#6c47c7', fontWeight: 600 }}>Baseline Date:</span>
          <span style={{ color: 'black', fontWeight: 400, marginLeft: 6 }}>25th May 2025</span>
        </div>
        <div style={{
          marginBottom: '14px',
          display: 'flex',
          alignItems: 'center',
          gap: '14px',
          justifyContent: 'center',
          width: '100%',
          fontFamily: fontStack
        }}>
          <label htmlFor="serverDropdown" style={{
            fontWeight: 600,
            fontSize: '17px',
            fontFamily: fontStack
          }}>
            Search Server / Database:
          </label>
          <div style={{
            display: 'flex',
            flexDirection: 'row',
            flex: 1,
            maxWidth: '400px',
            gap: '10px',
            fontFamily: fontStack
          }}>
            <input
              type="text"
              placeholder="Type Server or Database Name..."
              value={serverSearch}
              onChange={e => setServerSearch(e.target.value)}
              style={{
                flex: 2,
                padding: '8px 14px',
                borderRadius: '7px',
                border: '1px solid #bfc9d1',
                fontSize: '16px',
                background: '#f7f9fa',
                transition: 'box-shadow 0.2s',
                boxShadow: '0 2px 8px rgba(44,62,80,0.08)',
                outline: 'none',
                fontFamily: fontStack,
                fontWeight: 500
              }}
              onFocus={e => e.target.style.boxShadow = '0 0 0 2px #6c47c7'}
              onBlur={e => e.target.style.boxShadow = '0 2px 8px rgba(44,62,80,0.08)'}
            />
            <select
              id="serverDropdown"
              value={selectedServer}
              onChange={e => setSelectedServer(e.target.value)}
              style={{
                flex: 1,
                padding: '8px 14px',
                borderRadius: '7px',
                border: '1px solid #bfc9d1',
                fontSize: '16px',
                background: '#f7f9fa',
                boxShadow: '0 2px 8px rgba(44,62,80,0.08)',
                transition: 'box-shadow 0.2s',
                outline: 'none',
                fontFamily: fontStack,
                fontWeight: 500,
                cursor: 'pointer'
              }}
              onFocus={e => e.target.style.boxShadow = '0 0 0 2px rgb(57, 136, 205)'}
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
                padding: '8px 18px',
                borderRadius: '7px',
                border: 'none',
                background: 'linear-gradient(90deg, #6c47c7 0%, #34aadc 100%)',
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
        <div style={{
          display: 'flex',
          justifyContent: 'flex-end',
          alignItems: 'center',
          width: '100%',
          marginBottom: '8px',
          gap: '10px'
        }}>
          <label style={{ marginRight: 8, fontWeight: 500, color: '#6c47c7' }}>Sort by:</label>
          <select
            value={sortField}
            onChange={e => setSortField(e.target.value)}
            style={{
              padding: '6px 12px',
              borderRadius: '6px',
              border: '1px solid #bfc9d1',
              fontSize: '15px',
              background: '#f7f9fa',
              color: '#2c3e50',
              fontWeight: 500,
              cursor: 'pointer'
            }}
          >
            <option value="percentChange">DB Growth Percentage</option>
            <option value="totalDbSize">Total DB Size</option>
          </select>
          <select
            value={sortOrder}
            onChange={e => setSortOrder(e.target.value)}
            style={{
              padding: '6px 12px',
              borderRadius: '6px',
              border: '1px solid #bfc9d1',
              fontSize: '15px',
              background: '#f7f9fa',
              color: '#2c3e50',
              fontWeight: 500,
              cursor: 'pointer'
            }}
          >
            <option value="default">Default</option>
            <option value="desc">Descending</option>
            <option value="asc">Ascending</option>
          </select>
          <button
            onClick={handleExportExcel}
            style={{
              marginLeft: '8px',
              padding: '7px 18px',
              borderRadius: '7px',
              border: 'none',
              background: 'linear-gradient(90deg, #34aadc 0%, #6c47c7 100%)',
              color: '#fff',
              fontWeight: 600,
              fontSize: '15px',
              cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(44,62,80,0.08)',
              fontFamily: fontStack,
              transition: 'background 0.2s'
            }}
          >
            Export to Excel
          </button>
        </div>
        <div style={{ overflowX: 'auto', width: '100%', display: 'flex', justifyContent: 'center', fontFamily: fontStack }}>
          <table style={{
            borderCollapse: 'separate',
            borderSpacing: '0',
            width: '100%',
            background: '#fff',
            borderRadius: '14px',
            boxShadow: '0 2px 8px rgba(136,84,208,0.08)',
            textAlign: 'center',
            fontFamily: fontStack
          }}>
            <thead>
              <tr style={{
                background: 'linear-gradient(90deg, #6c47c7 0%, #34aadc 100%)',
                color: '#fff',
                fontFamily: fontStack
              }}>
                {[
                  "Server Name",
                  "Database Name",
                  "Total DB Size (GB)",
                  "Present DataFile Size (GB)",
                  "Baseline DataFile Size (GB)",
                  "DataFile Size Change (GB)",
                  "% of Total GB Used",
                  "DB Size Growth Percent", // Changed from Percent Change
                  "DB Growth Size Status",   // Changed from Status
                  "Date",
                  "" // Add an empty string for the Show/Hide Details button header
                ].map((col, idx) => (
                  <th
                    key={col + idx}
                    style={{
                      padding: '10px 6px',
                      border: 'none',
                      fontSize: '15px',
                      borderTopLeftRadius: idx === 0 ? '12px' : '0',
                      borderTopRightRadius: idx === 10 ? '12px' : '0',
                      fontWeight: 600,
                      fontFamily: fontStack,
                      letterSpacing: '0.2px',
                      textAlign: 'center',
                      minWidth: idx === 10 ? '120px' : undefined // Ensure button header has enough width
                    }}
                  >
                    {col}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sortedFilteredData.length === 0 ? (
                <tr>
                  <td colSpan={11} style={{
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
                sortedFilteredData.map((row, idx) => (
                  <React.Fragment key={idx}>
                    <tr style={{
                      background: idx % 2 === 0 ? '#f6f7fb' : '#fff',
                      transition: 'background 0.3s',
                      fontFamily: fontStack
                    }}>
                      <td style={{ padding: '10px 6px', fontFamily: fontStack }}>{row.ServerName}</td>
                      <td style={{ padding: '10px 6px', fontFamily: fontStack }}>{row.DatabaseName}</td>
                      <td style={{ padding: '10px 6px', fontFamily: fontStack }}>{row.TotalDatabaseSizeGB}</td>
                      <td style={{ padding: '10px 6px', fontFamily: fontStack }}>{row.TotalDataFileSizeGB}</td>
                      <td style={{ padding: '10px 6px', fontFamily: fontStack }}>{row.TotalDataFileSizeGB_baseline}</td>
                      <td style={{ padding: '10px 6px', fontFamily: fontStack }}>{row.TotalDataFileSizeChange}</td>
                      <td style={{ padding: '10px 6px', fontFamily: fontStack }}>{row.PercentageOfTotalGBUsed}</td>
                      <td style={{ padding: '10px 6px', fontFamily: fontStack }}>{row.TotalDataFileSizeGB_PercentChange}</td>
                      <td style={{
                        padding: '10px 6px',
                        color: row.DatabaseSizeStatus === 'Increased'
                          ? '#e74c3c'
                          : '#27ae60',
                        fontWeight: 'bold',
                        whiteSpace: 'nowrap',
                        fontFamily: fontStack
                      }}>
                        {row.DatabaseSizeStatus}
                      </td>
                      <td style={{ padding: '10px 6px', whiteSpace: 'nowrap', fontFamily: fontStack }}>{row.FormattedDate}</td>
                      <td>
                        <button
                          onClick={() => {
                            if (expandedDb === row.DatabaseName) {
                              setExpandedDb(null);
                            } else {
                              setExpandedDb(row.DatabaseName);
                              if (!topTables[row.DatabaseName]) fetchTopTables(row.DatabaseName);
                            }
                          }}
                          style={{
                            padding: '7px 16px',
                            borderRadius: 7,
                            border: 'none',
                            background: expandedDb === row.DatabaseName
                              ? 'linear-gradient(90deg, #e74c3c 0%, #f7b731 100%)'
                              : 'linear-gradient(90deg, #6c47c7 0%, #34aadc 100%)',
                            color: '#fff',
                            fontWeight: 600,
                            fontSize: '15px',
                            cursor: 'pointer',
                            boxShadow: '0 2px 8px rgba(44,62,80,0.08)',
                            fontFamily: fontStack,
                            transition: 'background 0.2s'
                          }}
                        >
                          {expandedDb === row.DatabaseName ? 'Hide Details' : 'Show Details'}
                        </button>
                      </td>
                    </tr>
                    {expandedDb === row.DatabaseName && (
                      <tr>
                        <td colSpan={12}>
                          <div style={{
                            display: 'flex',
                            gap: 16,
                            alignItems: 'flex-start',
                            background: 'linear-gradient(90deg, #6c47c7 0%, #34aadc 100%)',
                            borderRadius: 14,
                            padding: '12px 8px',
                            justifyContent: 'center'
                          }}>
                            {/* Graph */}
                            <div style={{ flex: 1, minWidth: 0 }}>
                              <Bar
                                data={{
                                  labels: [
                                    'Present DataFile Size (GB)',
                                    'Baseline DataFile Size (GB)',
                                    'DataFile Size Change (GB)',
                                    'DB Size Growth Percent'
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
                                      hoverBackgroundColor: [
                                        getBarHoverColor(row.DatabaseSizeStatus, 'TotalDataFileSizeGB'),
                                        getBarHoverColor(row.DatabaseSizeStatus, 'BaselineDataFileSizeGB'),
                                        getBarHoverColor(row.DatabaseSizeStatus, 'DataFileSizeChange'),
                                        getBarHoverColor(row.DatabaseSizeStatus, 'PercentChange')
                                      ],
                                      borderRadius: 12,
                                      borderSkipped: false
                                    }
                                  ]
                                }}
                                options={{
                                  ...getChartOptions(row.DatabaseName),
                                  plugins: {
                                    ...getChartOptions(row.DatabaseName).plugins,
                                    title: {
                                      ...getChartOptions(row.DatabaseName).plugins.title,
                                      color: '#fff',
                                      font: { size: 18, family: fontStack, weight: 'bold' },
                                      padding: { top: 10, bottom: 20 }
                                    }
                                  },
                                  scales: {
                                    x: {
                                      ...getChartOptions(row.DatabaseName).scales.x,
                                      ticks: { ...getChartOptions(row.DatabaseName).scales.x.ticks, color: '#fff' },
                                      title: { ...getChartOptions(row.DatabaseName).scales.x.title, color: '#fff' }
                                    },
                                    y: {
                                      ...getChartOptions(row.DatabaseName).scales.y,
                                      ticks: { ...getChartOptions(row.DatabaseName).scales.y.ticks, color: '#fff' },
                                      title: { ...getChartOptions(row.DatabaseName).scales.y.title, color: '#fff' }
                                    }
                                  }
                                }}
                              />
                            </div>
                            {/* Top 10 Tables */}
                            <div style={{
                              flex: 1,
                              background: '#f6f7fb',
                              borderRadius: 10,
                              padding: 10,
                              minWidth: 260,
                              display: 'flex',
                              flexDirection: 'column',
                              alignItems: 'center',
                              boxShadow: '0 2px 8px rgba(136,84,208,0.08)'
                            }}>
                              <h4 style={{ color: '#6c47c7', marginBottom: 8, textAlign: 'center', fontSize: 16 }}>Top 10 High-Sized Tables</h4>
                              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 14, textAlign: 'center' }}>
                                <thead>
                                  <tr style={{ background: '#e0eafc', color: '#2c3e50' }}>
                                    <th style={{ padding: 6, textAlign: 'center' }}>Table Name</th>
                                    <th style={{ padding: 6, textAlign: 'center' }}>Row Count</th>
                                    <th style={{ padding: 6, textAlign: 'center' }}>Size (GB)</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {(topTables[row.DatabaseName] || []).map((tbl, i) => (
                                    <tr key={tbl.TableName}>
                                      <td style={{ padding: 6, textAlign: 'center' }}>{tbl.TableName}</td>
                                      <td style={{ padding: 6, textAlign: 'center' }}>{tbl.RowCount.toLocaleString()}</td>
                                      <td style={{ padding: 6, textAlign: 'center' }}>{tbl.SizeGB}</td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))
              )}
            </tbody>
          </table>
        </div>
    </div>
  {/* Support Contact - Bottom Right */}
  <div
    style={{
      position: 'fixed',
      right: 24,
      bottom: 18,
      zIndex: 1000,
      background: 'rgba(255,255,255,0.95)',
      borderRadius: '10px',
      boxShadow: '0 2px 12px rgba(44,62,80,0.10)',
      padding: '10px 18px',
      fontSize: '15px',
      color: '#2c3e50',
      fontFamily: fontStack,
      display: 'flex',
      alignItems: 'center'
    }}
  >
    Please Reach out to&nbsp;
    <a
      href="mailto:CRSDBASUPPORT@cognizant.com?subject=1C%20Applications%20Database%20Growth%20Dashboard%20Support"
      style={{
        color: '#6c47c7',
        fontWeight: 700,
        textDecoration: 'underline',
        cursor: 'pointer'
      }}
      target="_blank"
      rel="noopener noreferrer"
    >
      ITOps 1C DBA Team
    </a>
    &nbsp;for further queries/Analysis.
  </div>
</div>
);
}
export default App;