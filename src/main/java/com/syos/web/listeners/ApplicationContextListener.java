package com.syos.web.listeners;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

/**
 * Application Context Listener
 * Initializes application when the web app starts
 */
@WebListener
public class ApplicationContextListener implements ServletContextListener {

    private static final Logger logger = LoggerFactory.getLogger(ApplicationContextListener.class);

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        logger.info("🚀 SYOS POS System Starting Up...");

        try {
            // Initialize application context
            String appName = sce.getServletContext().getInitParameter("appName");
            String appVersion = sce.getServletContext().getInitParameter("appVersion");

            logger.info("Initializing {} v{}", appName, appVersion);

            // Perform any application-wide initialization here
            initializeApplication();

            logger.info("✅ SYOS POS System Started Successfully");
            logger.info("📝 Application Name: {}", appName);
            logger.info("🔢 Version: {}", appVersion);
            logger.info("🌐 Context Path: {}", sce.getServletContext().getContextPath());

        } catch (Exception e) {
            logger.error("❌ Failed to initialize SYOS POS System", e);
            throw new RuntimeException("Application initialization failed", e);
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        logger.info("🛑 SYOS POS System Shutting Down...");

        try {
            // Perform cleanup tasks
            cleanupApplication();

            logger.info("✅ SYOS POS System Shut Down Successfully");
        } catch (Exception e) {
            logger.error("❌ Error during application shutdown", e);
        }
    }

    /**
     * Initialize application components
     */
    private void initializeApplication() {
        // Initialize database connections, service factories, etc.
        logger.info("Initializing application components...");

        // Add any application-specific initialization here
        // For example: database connection pools, cache initialization, etc.
    }

    /**
     * Cleanup application resources
     */
    private void cleanupApplication() {
        // Close database connections, cleanup resources, etc.
        logger.info("Cleaning up application resources...");

        // Add any application-specific cleanup here
    }
}