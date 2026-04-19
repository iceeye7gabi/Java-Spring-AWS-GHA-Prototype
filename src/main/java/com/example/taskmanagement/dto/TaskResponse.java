package com.example.taskmanagement.dto;

import com.example.taskmanagement.model.TaskStatus;

import java.time.Instant;

public record TaskResponse(
        Long id,
        String title,
        String description,
        TaskStatus status,
        Instant createdAt
) {
}
