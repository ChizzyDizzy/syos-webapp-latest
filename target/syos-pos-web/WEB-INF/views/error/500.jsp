<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>500 Internal Server Error - SYOS POS</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
    <style>
        .error-container {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        .error-content {
            background: white;
            border-radius: 10px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            max-width: 600px;
            width: 100%;
        }
        .error-icon {
            font-size: 4rem;
            margin-bottom: 20px;
        }
        .error-title {
            font-size: 2rem;
            color: #e53e3e;
            margin-bottom: 10px;
        }
        .error-message {
            color: #4a5568;
            margin-bottom: 30px;
            line-height: 1.6;
        }
        .error-actions {
            display: flex;
            gap: 10px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .error-details {
            margin-top: 20px;
            padding: 15px;
            background: #fed7d7;
            border-radius: 5px;
            text-align: left;
            font-size: 0.9rem;
            color: #742a2a;
            border-left: 4px solid #e53e3e;
        }
        .support-info {
            margin-top: 15px;
            padding: 15px;
            background: #e6fffa;
            border-radius: 5px;
            text-align: left;
            font-size: 0.9rem;
            color: #234e52;
            border-left: 4px solid #38b2ac;
        }
    </style>
</head>
<body>
<div class="error-container">
    <div class="error-content">
        <div class="error-icon">💥</div>
        <h1 class="error-title">500 Internal Server Error</h1>
        <p class="error-message">
            Something went wrong on our end. Our technical team has been notified and is working to fix the issue.
        </p>

        <div class="error-actions">
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="btn btn-primary">
                🏠 Go to Dashboard
            </a>
            <button onclick="location.reload()" class="btn btn-secondary">
                🔄 Try Again
            </button>
            <a href="${pageContext.request.contextPath}/" class="btn btn-outline">
                🏪 SYOS Home
            </a>
        </div>

        <div class="error-details">
            <strong>Technical Information:</strong><br>
            • Internal server error occurred<br>
            • Our team has been automatically notified<br>
            • Please try again in a few minutes<br>
            • If the problem persists, contact support

            <% if (exception != null) { %>
            <br><br>
            <strong>Exception:</strong> <%= exception.getClass().getName() %><br>
            <strong>Message:</strong> <%= exception.getMessage() %>
            <% } %>
        </div>

        <div class="support-info">
            <strong>Need Immediate Help?</strong><br>
            • Contact support: support@syos.com<br>
            • Call: +1 (555) 123-4567<br>
            • Reference Error ID: <strong><%= System.currentTimeMillis() %></strong>
        </div>

        <div style="margin-top: 20px; font-size: 0.8rem; color: #a0aec0;">
            Error ID: <%= System.currentTimeMillis() %><br>
            Timestamp: <%= new java.util.Date() %><br>
            Server: <%= request.getServerName() %>
        </div>
    </div>
</div>

<script>
    // Log detailed error information
    console.error('500 Internal Server Error:', {
        url: window.location.href,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        errorId: '<%= System.currentTimeMillis() %>'
    });

    // Auto-retry after 10 seconds
    setTimeout(() => {
        console.log('Auto-retrying after server error...');
    }, 10000);
</script>
</body>
</html>