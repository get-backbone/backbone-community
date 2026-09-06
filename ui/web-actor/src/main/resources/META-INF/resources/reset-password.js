function showLoading(isLoading) {
    const loading = document.getElementById('loading');
    const submitBtn = document.getElementById('submitBtn');
    if (loading) {
        loading.style.display = isLoading ? 'block' : 'none';
    }
    if (submitBtn) {
        submitBtn.disabled = isLoading;
    }
}

function hideError(errorEl) {
    if (errorEl) {
        errorEl.textContent = '';
        errorEl.style.display = 'none';
    }
}

function showError(message) {
    const errorEl = document.getElementById('error');
    if (!errorEl) {
        return;
    }
    errorEl.textContent = message;
    errorEl.style.display = 'block';
}

function showSuccess(message) {
    const success = document.getElementById('success');
    if (!success) {
        return;
    }
    success.textContent = message;
    success.classList.remove('hidden');
    success.style.display = 'block';
}

document.addEventListener('DOMContentLoaded', function() {
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token');
    const form = document.getElementById('resetPasswordForm');

    if (!token) {
        showError('This reset link is missing a token. Request a new password reset email.');
        if (form) {
            form.querySelectorAll('input, button').forEach((el) => { el.disabled = true; });
        }
        return;
    }

    if (!form) {
        return;
    }

    form.addEventListener('submit', async function(event) {
        event.preventDefault();

        const formData = new FormData(event.target);
        const newPassword = formData.get('newPassword');
        const confirmPassword = formData.get('confirmPassword');

        if (newPassword !== confirmPassword) {
            showError('Passwords do not match.');
            return;
        }

        showLoading(true);
        hideError(document.getElementById('error'));

        try {
            const url = AppConfig.apiUrl(AppConfig.API_PATHS.AUTH_RESET_PASSWORD);
            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ token, newPassword })
            });

            showLoading(false);

            if (!response.ok) {
                let message = 'Unable to reset password. The link may be invalid or expired.';
                try {
                    const payload = await response.json();
                    if (payload && payload.error) {
                        message = payload.error;
                    }
                } catch (_) {
                    // keep default message
                }
                showError(message);
                return;
            }

            showSuccess('Password updated. You can now log in with your new password.');
            form.reset();
            setTimeout(() => {
                window.location.href = AppConfig.ROUTES.LOGIN;
            }, 1500);
        } catch (e) {
            showLoading(false);
            showError('Unable to reset password. Please try again.');
        }
    });
});
