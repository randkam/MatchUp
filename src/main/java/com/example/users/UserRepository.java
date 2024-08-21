package com.example.users;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User>findUserByUserEmail(String userEmail);
    Optional<User>findUserByUserName(String userName);
}
