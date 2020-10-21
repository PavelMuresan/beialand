package com.beia_consult_international.solomon.service;

import com.beia_consult_international.solomon.dto.UserDto;
import com.beia_consult_international.solomon.exception.UserNotFoundException;
import com.beia_consult_international.solomon.model.Topic;
import com.beia_consult_international.solomon.model.User;
import com.beia_consult_international.solomon.repository.UserRepository;
import com.beia_consult_international.solomon.service.mapper.UserMapper;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public Boolean validUserDetails(String username, String password) {
        User user = userRepository
                .findUserByUsername(username)
                .orElseThrow(UserNotFoundException::new);
        return passwordEncoder.matches(password, user.getPassword());
    }

    public Boolean userExists(UserDto userDto) {
        try { findUserByUsername(userDto.getUsername()); }
        catch (UserNotFoundException e) { return false; }
        return true;
    }

    public UserDto findById(Long id) {
        return UserMapper.mapToDto(userRepository
                .findById(id)
                .orElseThrow(UserNotFoundException::new));
    }

    public UserDto findUserByUsername(String username) {
        return UserMapper.mapToDto(userRepository
                .findUserByUsername(username)
                .orElseThrow(UserNotFoundException::new));
    }

    public UserDto findUserByUsername(String username, String usersPhotoPath) {
        return UserMapper.mapToDto(userRepository
                .findUserByUsername(username)
                .orElseThrow(UserNotFoundException::new), usersPhotoPath);
    }

    public void save(UserDto userDto, String password) {
        User user = UserMapper.mapToModel(userDto);
        user.setPassword(passwordEncoder.encode(password));
        userRepository.save(user);
    }

    public void saveToken(long userId, String token) {
        User user = userRepository
                .findById(userId)
                .orElseThrow(UserNotFoundException::new);
        user.setFcmToken(token.substring(1, token.length() - 1));
        userRepository.save(user);
    }

    public void sendChatNotificationsToAllAgents(long userId) throws FirebaseMessagingException {
        User user = userRepository.findById(userId).orElseThrow(UserNotFoundException::new);
        Message message = Message
                .builder()
                .putData("title", user.getUsername() + " wants to chat with you...")
                .putData("message", "Click to respond")
                .setTopic(Topic.AGENT.name())
                .build();
        FirebaseMessaging.getInstance().send(message);
    }
}
