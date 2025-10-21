package uy.edu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uy.edu.model.CoffeeOrder;

@Repository
public interface CoffeeOrderRepository extends JpaRepository<CoffeeOrder, Long> {}
