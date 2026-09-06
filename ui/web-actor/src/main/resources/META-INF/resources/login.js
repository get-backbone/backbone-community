// Handle email form toggle and social login redirects
document.addEventListener('DOMContentLoaded', function() {
    AuthUtils.clearAuthData();

    const linkedInBtn = document.querySelector('a.auth-btn[href*="/auth/linkedin/login"]');
    if (linkedInBtn) {
        linkedInBtn.href = AppConfig.apiUrl(AppConfig.API_PATHS.AUTH_LINKEDIN_LOGIN);
    }

    const googleBtn = document.getElementById('googleBtn');
    if (googleBtn) {
        googleBtn.addEventListener('click', function() {
            window.location.href = AppConfig.apiUrl(AppConfig.API_PATHS.AUTH_GOOGLE_LOGIN);
        });
    }

    const emailBtn = document.getElementById('emailBtn');
    const emailFormContainer = document.getElementById('emailFormContainer');

    if (emailBtn && emailFormContainer) {
        emailBtn.addEventListener('click', function() {
            emailFormContainer.classList.toggle('hidden');
            if (!emailFormContainer.classList.contains('hidden')) {
                const usernameInput = document.getElementById('username');
                if (usernameInput) {
                    setTimeout(() => usernameInput.focus(), 100);
                }
            }
        });
    }

    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', async function(event) {
        event.preventDefault();

        const formData = new FormData(event.target);
        const data = {
            username: formData.get('username'),
            password: formData.get('password')
        };
        const jsonBody = JSON.stringify(data);

        showLoading(true);
        hideError(document.getElementById('error'));

        try {
            const loginUrl = AppConfig.apiUrl(AppConfig.API_PATHS.AUTH_LOGIN || '/auth/login');
            const response = await fetch(loginUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: jsonBody
            });

            const responseText = await response.text();
            showLoading(false);

            let authResult = null;
            try {
                authResult = JSON.parse(responseText);
            } catch (e) {
                handleLoginError(response, responseText);
                return;
            }

            if (response.ok && authResult.success && authResult.accessToken) {
                AuthUtils.storeTokens(authResult);
                window.location.href = `/${AppConfig.ROUTES.DASHBOARD}`;
            } else {
                handleLoginError(response, responseText);
            }
        } catch (error) {
            console.error('Login error:', error);
            showLoading(false);
            handleLoginError(null, error.message);
        }
        });
    }
});

function handleLoginError(response, responseText) {
    const errorDiv = document.getElementById('error');
    let errorMessage = `Status: ${response ? response.status : 'Network Error'}\n\n`;

    try {
        const errorData = JSON.parse(responseText || '{}');
        const prettyJson = JSON.stringify(errorData, null, 2);
        errorMessage += `Response:\n${prettyJson}`;
    } catch (e) {
        if (responseText) {
            errorMessage += `Response:\n${responseText}`;
        } else {
            errorMessage += `Response: No response text available`;
        }
    }

    showError(errorDiv, errorMessage);
}
