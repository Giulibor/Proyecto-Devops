package uy.edu.ucu.cafeteria_app.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import uy.edu.ucu.cafeteria_app.service.OrderService;

import java.time.Instant;
import java.util.Map;

@ControllerAdvice
public class ErrorHandler {

    @ExceptionHandler(OrderService.NotFoundException.class)
    public ResponseEntity<?> handleNotFound(OrderService.NotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                Map.of("timestamp", Instant.now().toString(),
                       "status", 404,
                       "error", "Not Found",
                       "message", ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<?> handleEnumMismatch(MethodArgumentTypeMismatchException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
                Map.of("timestamp", Instant.now().toString(),
                       "status", 400,
                       "error", "Bad Request",
                       "message", "Invalid parameter: " + ex.getName()));
    }
}
