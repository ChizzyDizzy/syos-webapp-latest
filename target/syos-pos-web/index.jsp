<!DOCTYPE html>
<html>
<head>
    <title>SYOS POS System</title>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            text-align: center;
        }
        .status {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
        }
        .endpoints {
            margin-top: 30px;
        }
        .endpoint {
            background: #f8f9fa;
            padding: 10px;
            margin: 10px 0;
            border-left: 4px solid #007bff;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>🚀 SYOS POS System</h1>
    <div class="status">
        <strong>Status:</strong> Application is running successfully!
    </div>

    <p>Welcome to the SYOS (Synex Outlet Store) Point of Sale System.</p>

    <div class="endpoints">
        <h3>Available API Endpoints:</h3>

        <div class="endpoint">
            <strong>User Management</strong><br>
            POST /api/user/login - User authentication<br>
            POST /api/user/register - User registration (Admin only)<br>
            POST /api/user/logout - User logout<br>
            GET /api/user/profile - Get user profile<br>
            GET /api/user/session-info - Get session information
        </div>

        <div class="endpoint">
            <strong>Sales Management</strong><br>
            GET /api/sales/available-items - Get items for sale<br>
            POST /api/sales/create - Create new sale<br>
            GET /api/sales/bills - Get all bills<br>
            GET /api/sales/today - Get today's bills
        </div>

        <div class="endpoint">
            <strong>Inventory Management</strong><br>
            GET /api/inventory/items - Get all items<br>
            POST /api/inventory/add-stock - Add new stock<br>
            POST /api/inventory/move-to-shelf - Move to shelf<br>
            GET /api/inventory/statistics - Get inventory stats
        </div>

        <div class="endpoint">
            <strong>Reports</strong><br>
            GET /api/reports/daily-sales - Daily sales report<br>
            GET /api/reports/stock - Stock report<br>
            GET /api/reports/reorder - Reorder report<br>
            GET /api/reports/reshelve - Reshelve report
        </div>
    </div>

    <div style="margin-top: 30px; text-align: center; color: #666;">
        <p>Use Postman or similar tool to test the API endpoints.</p>
    </div>
</div>
</body>
</html>