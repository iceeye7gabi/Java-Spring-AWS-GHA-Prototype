package com.example.taskmanagement.service;

import com.example.taskmanagement.dto.CreateTaskRequest;
import com.example.taskmanagement.dto.TaskResponse;
import com.example.taskmanagement.dto.UpdateTaskRequest;
import com.example.taskmanagement.exception.ResourceNotFoundException;
import com.example.taskmanagement.model.Task;
import com.example.taskmanagement.model.TaskStatus;
import com.example.taskmanagement.repository.TaskRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    @InjectMocks
    private TaskService taskService;

    @Test
    void createTask_persistsAndReturnsResponse() {
        CreateTaskRequest request = CreateTaskRequest.builder()
                .title("Write tests")
                .description("Service layer")
                .status(TaskStatus.IN_PROGRESS)
                .build();

        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> {
            Task t = invocation.getArgument(0);
            t.setId(1L);
            t.setCreatedAt(Instant.parse("2025-01-01T12:00:00Z"));
            return t;
        });

        TaskResponse result = taskService.create(request);

        assertThat(result.id()).isEqualTo(1L);
        assertThat(result.title()).isEqualTo("Write tests");
        assertThat(result.description()).isEqualTo("Service layer");
        assertThat(result.status()).isEqualTo(TaskStatus.IN_PROGRESS);
        assertThat(result.createdAt()).isEqualTo(Instant.parse("2025-01-01T12:00:00Z"));

        ArgumentCaptor<Task> captor = ArgumentCaptor.forClass(Task.class);
        verify(taskRepository).save(captor.capture());
        assertThat(captor.getValue().getTitle()).isEqualTo("Write tests");
    }

    @Test
    void createTask_defaultsStatusToTodoWhenOmitted() {
        CreateTaskRequest request = CreateTaskRequest.builder()
                .title("No status")
                .build();

        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> {
            Task t = invocation.getArgument(0);
            t.setId(2L);
            t.setCreatedAt(Instant.now());
            return t;
        });

        TaskResponse result = taskService.create(request);

        assertThat(result.status()).isEqualTo(TaskStatus.TODO);
    }

    @Test
    void getTask_returnsTaskWhenFound() {
        Task task = Task.builder()
                .id(10L)
                .title("Found")
                .description("x")
                .status(TaskStatus.DONE)
                .createdAt(Instant.parse("2025-06-01T00:00:00Z"))
                .build();
        when(taskRepository.findById(10L)).thenReturn(Optional.of(task));

        TaskResponse result = taskService.findById(10L);

        assertThat(result.title()).isEqualTo("Found");
        assertThat(result.status()).isEqualTo(TaskStatus.DONE);
    }

    @Test
    void getTask_throwsWhenMissing() {
        when(taskRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.findById(99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("99");
    }

    @Test
    void deleteTask_removesWhenExists() {
        when(taskRepository.existsById(5L)).thenReturn(true);

        taskService.deleteById(5L);

        verify(taskRepository).deleteById(5L);
    }

    @Test
    void deleteTask_throwsWhenMissing() {
        when(taskRepository.existsById(7L)).thenReturn(false);

        assertThatThrownBy(() -> taskService.deleteById(7L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("7");

        verify(taskRepository, never()).deleteById(any());
    }

    @Test
    void findAll_returnsMappedList() {
        Task a = Task.builder()
                .id(1L)
                .title("A")
                .description(null)
                .status(TaskStatus.TODO)
                .createdAt(Instant.EPOCH)
                .build();
        when(taskRepository.findAll()).thenReturn(List.of(a));

        List<TaskResponse> list = taskService.findAll();

        assertThat(list).hasSize(1);
        assertThat(list.get(0).title()).isEqualTo("A");
    }

    @Test
    void updateTask_updatesFields() {
        Task existing = Task.builder()
                .id(3L)
                .title("Old")
                .description("old desc")
                .status(TaskStatus.TODO)
                .createdAt(Instant.EPOCH)
                .build();
        when(taskRepository.findById(3L)).thenReturn(Optional.of(existing));

        UpdateTaskRequest req = UpdateTaskRequest.builder()
                .title("New title")
                .description("new desc")
                .status(TaskStatus.IN_PROGRESS)
                .build();

        TaskResponse result = taskService.update(3L, req);

        assertThat(result.title()).isEqualTo("New title");
        assertThat(result.description()).isEqualTo("new desc");
        assertThat(result.status()).isEqualTo(TaskStatus.IN_PROGRESS);
    }
}
