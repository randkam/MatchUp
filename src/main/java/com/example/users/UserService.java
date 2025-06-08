package com.example.users;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.transaction.Transactional;


@Service
public class UserService {
    private final UserRepository userRepository;
	@Autowired
	public UserService(UserRepository userRepository) {
		this.userRepository = userRepository;
	}

	public List<User> getUsers(){
        return userRepository.findAll();

	}


	public User getUser (String userEmail){
		return userRepository.findUserByUserEmail(userEmail)
		.orElseThrow(() -> new IllegalStateException("User not found"));
	}


	public void addNewUser( User user){
        Optional<User>userEmailOptional = userRepository.findUserByUserEmail(user.getEmail());
		if (userEmailOptional.isPresent()){
			throw new IllegalStateException("Email is Taken");
		}
		Optional<User>userNameOptional = userRepository.findUserByUserName(user.getUserName());
		if (userNameOptional.isPresent()){
			throw new IllegalStateException("Username is Taken");
		}
		
		userRepository.save(user);
		
		
    }	



	public void deleteUser( Long userId){
      userRepository.deleteById(userId);
	  
    }

	@Transactional
	public void updateUser(Long userId, String userName, String userEmail, String userNickName, String userPassword) {
		User user = userRepository.findById(userId)
				.orElseThrow(() -> new IllegalStateException("User not found"));
		
		if (userName != null && userName.length() > 0) {
			Optional<User> userNameOptional = userRepository.findUserByUserName(userName);
			if (userNameOptional.isPresent()) {
				throw new IllegalStateException("Username is Taken");
			} else {
				user.setUserName(userName);
			}
		}
		if (userEmail != null && userEmail.length() > 0) {
			Optional<User> userEmailOptional = userRepository.findUserByUserEmail(userEmail);
			if (userEmailOptional.isPresent()) {
				throw new IllegalStateException("Email is Taken");
			} else {
				user.setEmail(userEmail);
			}
		}
		if (userNickName != null && userNickName.length() > 0) {
			user.setNickName(userNickName);
		}
		if (userPassword != null && userPassword.length() > 0) {
			user.setPassword(userPassword);
		}

	}

	@Transactional
	public void updateProfilePicture(Long userId, String profilePictureUrl) {
		User user = userRepository.findById(userId)
				.orElseThrow(() -> new IllegalStateException("User not found"));
		user.setProfilePictureUrl(profilePictureUrl);
	}

	public String getUsernameById(Long userId) {
		User user = userRepository.findById(userId)
				.orElseThrow(() -> new IllegalStateException("User not found"));
		return user.getUserName();
	}
}