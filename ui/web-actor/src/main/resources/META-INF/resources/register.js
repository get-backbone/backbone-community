// Handle form submission
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('registerForm').addEventListener('submit', async function(event) {
        event.preventDefault();
        
        // Clear previous errors
        hideError(document.getElementById('error'));
        
        // Validate form fields
        const validationError = validateForm();
        if (validationError) {
            showError(document.getElementById('error'), validationError);
            return;
        }
        
        const formData = new FormData(event.target);

        const data = {
            name: formData.get('name').trim(),
            emailAddress: formData.get('email').trim(),
            password: formData.get('password')
        };

        const jsonBody = JSON.stringify(data);
        
        console.log('Sending registration request:', jsonBody);
        console.log('Request data object:', data);
        
        // Show loading state
        showLoading(true);
        
        try {
            const registerUrl = AppConfig.apiUrl(AppConfig.API_PATHS.AUTH_REGISTER);
            const response = await fetch(registerUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: jsonBody
            });
            
            // Log response for debugging
            const responseText = await response.text();
            console.log('Registration response status:', response.status);
            console.log('Registration response text:', responseText);
            console.log('Registration response headers:', response.headers);
            
            // Reset loading state
            showLoading(false);
            
            // Parse the response to check for success
            let registerResult = null;
            try {
                registerResult = JSON.parse(responseText);
            } catch (e) {
                console.warn('Could not parse registration response:', e);
                handleRegisterError(response, responseText);
                return;
            }
            
            // Check if registration was successful
            // Backend returns 200 OK even on failure, so check the success field
            if (response.ok && registerResult.success === true) {
                console.log('Registration successful:', registerResult);
                
                // After successful registration, login to get JWT tokens
                const email = formData.get('email').trim();
                const password = formData.get('password');
                
                try {
                    const loginData = {
                        username: email,
                        password: password
                    };
                    const loginJsonBody = JSON.stringify(loginData);
                    
                    console.log('Logging in after registration...');
                    const loginUrl = AppConfig.apiUrl(AppConfig.API_PATHS.AUTH_LOGIN);
                    const loginResponse = await fetch(loginUrl, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: loginJsonBody
                    });
                    
                    const loginResponseText = await loginResponse.text();
                    console.log('Login response status:', loginResponse.status);
                    console.log('Login response text:', loginResponseText);
                    
                    let authResult = null;
                    try {
                        authResult = JSON.parse(loginResponseText);
                    } catch (e) {
                        console.warn('Could not parse login response:', e);
                        handleRegisterError(loginResponse, 'Registration succeeded but login failed');
                        return;
                    }
                    
                    // Check if login was successful
                    if (loginResponse.ok && authResult.success && authResult.accessToken) {
                        // Store JWT tokens and user data
                        AuthUtils.storeTokens(authResult);
                        
                        console.log('Login successful. Stored tokens and user ID:', authResult.user?.id);
                        
                        // Success - redirect to dashboard (user is fully registered and authenticated)
                        window.location.href = AppConfig.ROUTES.DASHBOARD;
                    } else {
                        // Login failed
                        handleRegisterError(loginResponse, 'Registration succeeded but login failed: ' + (authResult.errorMessage || authResult.error || 'Unknown error'));
                    }
                } catch (loginError) {
                    console.error('Error logging in after registration:', loginError);
                    handleRegisterError(null, 'Registration succeeded but login failed: ' + loginError.message);
                }
            } else {
                // Error - show error message
                const errorMessage = registerResult.errorMessage || registerResult.error || 'Registration failed';
                handleRegisterError(response, errorMessage);
            }
        } catch (error) {
            console.error('Registration error:', error);
            showLoading(false);
            handleRegisterError(null, error.message);
        }
    });
});

function validateForm() {
    const name = document.getElementById('name').value.trim();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;

    if (!name) {
        return 'Name is required';
    }

    if (!email) {
        return 'Email address is required';
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return 'Please enter a valid email address';
    }

    if (!password) {
        return 'Password is required';
    }

    if (password.length < 6) {
        return 'Password must be at least 6 characters long';
    }

    return null;
}

function handleRegisterError(response, errorMessage) {
    const errorDiv = document.getElementById('error');
    
    // If errorMessage is already a string, use it directly
    // Otherwise, try to parse it as JSON
    let displayMessage = errorMessage;
    
    if (typeof errorMessage === 'string') {
        // Check if it's JSON
        try {
            const errorData = JSON.parse(errorMessage);
            if (errorData.error) {
                displayMessage = errorData.error;
            } else if (errorData.errorMessage) {
                displayMessage = errorData.errorMessage;
            } else {
                displayMessage = JSON.stringify(errorData, null, 2);
            }
        } catch (e) {
            // Not JSON, use as-is
            displayMessage = errorMessage;
        }
    }
    
    // Add status code if available
    if (response && response.status) {
        displayMessage = `Error (${response.status}): ${displayMessage}`;
    } else if (!response) {
        displayMessage = `Network Error: ${displayMessage}`;
    }
    
    showError(errorDiv, displayMessage);
}


