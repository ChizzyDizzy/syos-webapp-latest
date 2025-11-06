package com.syos.web.session;

import com.syos.domain.entities.User;
import com.syos.domain.valueobjects.UserRole;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Session Manager
 * Manages HTTP sessions for authenticated users in the web application
 *
 * This class provides thread-safe session management including:
 * - User authentication state
 * - Session attributes
 * - Session invalidation
 * - User information retrieval
 */
public class SessionManager {

    // Session attribute keys
    private static final String ATTR_USER = "currentUser";
    private static final String ATTR_USER_ID = "userId";
    private static final String ATTR_USERNAME = "username";
    private static final String ATTR_USER_ROLE = "userRole";
    private static final String ATTR_LOGIN_TIME = "loginTime";
    private static final String ATTR_LAST_ACTIVITY = "lastActivity";

    // Session timeout in seconds (30 minutes)
    private static final int SESSION_TIMEOUT = 1800;

    /**
     * Create a new session for an authenticated user
     *
     * @param request the HTTP request
     * @param user the authenticated user
     */
    public static void createUserSession(HttpServletRequest request, User user) {
        HttpSession session = request.getSession(true);
        session.setMaxInactiveInterval(SESSION_TIMEOUT);

        // Store user information in session
        session.setAttribute(ATTR_USER, user);
        session.setAttribute(ATTR_USER_ID, user.getId().getValue());
        session.setAttribute(ATTR_USERNAME, user.getUsername());
        session.setAttribute(ATTR_USER_ROLE, user.getRole().name());
        session.setAttribute(ATTR_LOGIN_TIME, LocalDateTime.now().toString());
        session.setAttribute(ATTR_LAST_ACTIVITY, LocalDateTime.now().toString());
    }

    /**
     * Get the current user from the session
     *
     * @param request the HTTP request
     * @return the current user, or null if not logged in
     */
    public static User getCurrentUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }

        updateLastActivity(session);
        return (User) session.getAttribute(ATTR_USER);
    }

    /**
     * Get the current user's ID from the session
     *
     * @param request the HTTP request
     * @return the user ID, or null if not logged in
     */
    public static Long getCurrentUserId(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }

        return (Long) session.getAttribute(ATTR_USER_ID);
    }

    /**
     * Get the current username from the session
     *
     * @param request the HTTP request
     * @return the username, or null if not logged in
     */
    public static String getCurrentUsername(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }

        return (String) session.getAttribute(ATTR_USERNAME);
    }

    /**
     * Get the current user's role from the session
     *
     * @param request the HTTP request
     * @return the user role, or null if not logged in
     */
    public static UserRole getCurrentUserRole(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }

        String roleName = (String) session.getAttribute(ATTR_USER_ROLE);
        return roleName != null ? UserRole.valueOf(roleName) : null;
    }

    /**
     * Check if a user is currently logged in
     *
     * @param request the HTTP request
     * @return true if user is logged in, false otherwise
     */
    public static boolean isUserLoggedIn(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null && session.getAttribute(ATTR_USER) != null;
    }

    /**
     * Check if the current user has a specific role
     *
     * @param request the HTTP request
     * @param role the role to check
     * @return true if user has the role, false otherwise
     */
    public static boolean hasRole(HttpServletRequest request, UserRole role) {
        UserRole userRole = getCurrentUserRole(request);
        return userRole != null && userRole == role;
    }

    /**
     * Check if the current user has any of the specified roles
     *
     * @param request the HTTP request
     * @param roles the roles to check
     * @return true if user has any of the roles, false otherwise
     */
    public static boolean hasAnyRole(HttpServletRequest request, UserRole... roles) {
        UserRole userRole = getCurrentUserRole(request);
        if (userRole == null) {
            return false;
        }

        for (UserRole role : roles) {
            if (userRole == role) {
                return true;
            }
        }
        return false;
    }

    /**
     * Get the login time for the current session
     *
     * @param request the HTTP request
     * @return the login time as a string, or null if not logged in
     */
    public static String getLoginTime(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }

        return (String) session.getAttribute(ATTR_LOGIN_TIME);
    }

    /**
     * Get the last activity time for the current session
     *
     * @param request the HTTP request
     * @return the last activity time as a string, or null if not logged in
     */
    public static String getLastActivity(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }

        return (String) session.getAttribute(ATTR_LAST_ACTIVITY);
    }

    /**
     * Get the session duration in minutes
     *
     * @param request the HTTP request
     * @return the session duration in minutes, or 0 if not logged in
     */
    public static long getSessionDuration(HttpServletRequest request) {
        String loginTimeStr = getLoginTime(request);
        if (loginTimeStr == null) {
            return 0;
        }

        try {
            LocalDateTime loginTime = LocalDateTime.parse(loginTimeStr);
            LocalDateTime now = LocalDateTime.now();
            return java.time.Duration.between(loginTime, now).toMinutes();
        } catch (Exception e) {
            return 0;
        }
    }

    /**
     * Update the last activity timestamp for the current session
     *
     * @param session the HTTP session
     */
    private static void updateLastActivity(HttpSession session) {
        session.setAttribute(ATTR_LAST_ACTIVITY, LocalDateTime.now().toString());
    }

    /**
     * Invalidate the current user session (logout)
     *
     * @param request the HTTP request
     */
    public static void invalidateSession(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
    }

    /**
     * Get session information as a formatted string
     * Useful for logging and debugging
     *
     * @param request the HTTP request
     * @return session information string
     */
    public static String getSessionInfo(HttpServletRequest request) {
        if (!isUserLoggedIn(request)) {
            return "No active session";
        }

        StringBuilder info = new StringBuilder();
        info.append("User: ").append(getCurrentUsername(request));
        info.append(" | Role: ").append(getCurrentUserRole(request));
        info.append(" | Duration: ").append(getSessionDuration(request)).append(" min");
        info.append(" | Session ID: ").append(request.getSession(false).getId());

        return info.toString();
    }

    /**
     * Check if the session is about to expire (within 5 minutes)
     *
     * @param request the HTTP request
     * @return true if session is about to expire, false otherwise
     */
    public static boolean isSessionAboutToExpire(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return false;
        }

        int maxInactiveInterval = session.getMaxInactiveInterval();
        long lastAccessedTime = session.getLastAccessedTime();
        long currentTime = System.currentTimeMillis();
        long inactiveTime = (currentTime - lastAccessedTime) / 1000; // in seconds

        // Check if less than 5 minutes remaining
        return (maxInactiveInterval - inactiveTime) < 300;
    }
}