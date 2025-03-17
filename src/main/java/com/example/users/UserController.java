package com.example.users;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;


@RestController
@RequestMapping(path = "api/v1/users")
public class UserController {
    private final UserService userService;
    
    
    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
	public List<User> getUsers(){
       return userService.getUsers();

	}

    @GetMapping(path = "{email}")
    public User getUser(@PathVariable("email") String userEmail) {
    return userService.getUser(userEmail);
    }

    @PostMapping
    public void registerNewUser( @RequestBody  User user){
        user.setPassword(user.getUserPassword());
        userService.addNewUser(user);
            
    }

    @DeleteMapping(path =  "{userId}")
    public void deleteUser(@PathVariable("userId") Long userId){
        userService.deleteUser(userId);
    }

    @PutMapping(path = "{userId}")
    public void updateUser(@PathVariable("userId") long userId, @RequestParam(required = false) String userName,@RequestParam(required = false) String userEmail,@RequestParam(required = false) String userNickName,@RequestParam(required = false) String userPassword){
        userService.updateUser(userId, userName, userEmail, userNickName, userPassword);
    }

    
} 
    