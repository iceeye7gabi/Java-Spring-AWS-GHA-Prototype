package com.example.taskmanagement.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Smoke check after a GitHub Actions deploy: CloudWatch logs contain {@code deploy_check version=…},
 * and {@code GET /deploy-check} returns the same token (open EB URL + path in a browser).
 */
@RestController
public class DeployCheckController implements ApplicationRunner {

    public static final String VERSION = "gha-smoke-1";

    private static final Logger log = LoggerFactory.getLogger(DeployCheckController.class);

    @Override
    public void run(ApplicationArguments args) {
        log.info("deploy_check version={}", VERSION);
    }

    @GetMapping("/deploy-check")
    public String deployCheck() {
        return "deploy-check " + VERSION;
    }
}
