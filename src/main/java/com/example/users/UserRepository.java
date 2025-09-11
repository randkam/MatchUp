package com.example.users;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User>findUserByUserEmail(String userEmail);
    Optional<User>findUserByUserName(String userName);
    
    @Query("SELECT u FROM User u WHERE LOWER(u.userName) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(u.userNickName) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(u.userEmail) LIKE LOWER(CONCAT('%', :q, '%'))")
    java.util.List<User> searchUsers(String q);
}
