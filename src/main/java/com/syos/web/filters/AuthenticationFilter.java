package com.syos.web.filters;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Authentication Filter - Protects secured endpoints by checking user authentication
 */
public class AuthenticationFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization logic
        System.out.println("AuthenticationFilter initialized");
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);

        String path = httpRequest.getRequestURI();

        System.out.println("AuthenticationFilter: Checking access to " + path);

        // Check if user is authenticated (for now, just allow everything)
        // TODO: Add proper authentication logic here
        if (session == null || session.getAttribute("user") == null) {
            System.out.println("AuthenticationFilter: User not authenticated for " + path);
            // For now, we'll allow access but in production, you'd redirect to login
            // httpResponse.sendRedirect(httpRequest.getContextPath() + "/login");
            // return;
        } else {
            System.out.println("AuthenticationFilter: User authenticated for " + path);
        }

        // Continue with the filter chain
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        // Cleanup logic
        System.out.println("AuthenticationFilter destroyed");
    }
}