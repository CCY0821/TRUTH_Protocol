package com.truthprotocol.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * Utility class to generate BCrypt password hashes for testing
 */
public class PasswordHashGenerator {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(10);

        String password = "admin123";
        String hash = encoder.encode(password);

        System.out.println("Password: " + password);
        System.out.println("BCrypt Hash: " + hash);
        System.out.println();

        // Verify the hash works
        boolean matches = encoder.matches(password, hash);
        System.out.println("Verification: " + (matches ? "✓ SUCCESS" : "✗ FAILED"));

        // Test against the hash in the script
        String existingHash = "$2a$10$N9qo8uLOickgx2ZMRZoMye/IY/lGhzzN7mIQGLJ9.OrVLWyJkzJVy";
        boolean existingMatches = encoder.matches(password, existingHash);
        System.out.println();
        System.out.println("Testing existing hash from script:");
        System.out.println("Hash: " + existingHash);
        System.out.println("Matches 'admin123': " + (existingMatches ? "✓ YES" : "✗ NO"));
    }
}
