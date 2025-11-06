<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 Not Found - SYOS POS</title>
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
            max-width: 500px;
            width: 100%;
        }
        .error-icon {
            font-size: 4rem;
            margin-bottom: 20px;
        }
        .error-title {
            font-size: 2rem;
            color: #805ad5;
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
            background: #f7fafc;
            border-radius: 5px;
            text-align: left;
            font-size: 0.9rem;
            color: #718096;
        }
        .suggestions {
            text-align: left;
            margin-top: 15px;
        }
        .suggestions ul {
            padding-left: 20px;
            margin: 10px 0;
        }
        .suggestions li {
            margin-bottom: 5px;
        }
    </style>
</head>
<body>
<div class="error-container">
    <div class="error-content">
        <div class="error-icon">🔍</div>
        <h1 class="error-title">404 Not Found</h1>
        <p class="error-message">
            The page you're looking for doesn't exist. It might have been moved, deleted, or you entered the wrong URL.
        </p>

        <div class="error-actions">
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="btn btn-primary">
                🏠 Go to Dashboard
            </a>
            <button onclick="history.back()" class="btn btn-secondary">
                ↩️ Go Back
            </button>
            <a href="${pageContext.request.contextPath}/" class="btn btn-outline">
                🏪 SYOS Home
            </a>
        </div>

        <div class="error-details">
            <strong>Requested URL:</strong><br>
            <code id="requested-url">Loading...</code>

            <div class="suggestions">
                <strong>Suggestions:</strong>
                <ul>
                    <li>Check the URL for typos</li>
                    <li>Use the navigation menu to find the page</li>
                    <li>Contact support if you believe this is an error</li>
                    <li>Return to the dashboard and try again</li>
                </ul>
            </div>
        </div>

        <div style="margin-top: 20px; font-size: 0.8rem; color: #a0aec0;">
            Request ID: <%= System.currentTimeMillis() %><br>
            Timestamp: <%= new java.util.Date() %>
        </div>
    </div>
</div>

<script>
    // Display the requested URL
    document.getElementById('requested-url').textContent = window.location.href;

    console.error('404 Not Found Error:', {
        url: window.location.href,
        referrer: document.referrer
    });
</script>
</body>
</html>