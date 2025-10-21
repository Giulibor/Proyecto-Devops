package uy.edu.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import uy.edu.model.CoffeeOrder;
import uy.edu.model.OrderStatus;
import uy.edu.service.OrderService;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

  private final OrderService orderService;

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public CoffeeOrder create(@RequestBody CoffeeOrder body) {
    return orderService.create(body);
  }

  @GetMapping
  public List<CoffeeOrder> list() {
    return orderService.list();
  }

  @GetMapping("/{id}")
  public CoffeeOrder get(@PathVariable Long id) {
    return orderService.get(id);
  }

  @PatchMapping("/{id}/status/{status}")
  public CoffeeOrder updateStatus(@PathVariable Long id, @PathVariable OrderStatus status) {
    return orderService.updateStatus(id, status);
  }

  @DeleteMapping("/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void delete(@PathVariable Long id) {
    orderService.delete(id);
  }
}