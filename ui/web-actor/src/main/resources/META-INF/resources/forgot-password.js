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
    const form = document.getElementById('forgotPasswordForm');
    if (!form) {
        return;
    }

    form.addEventListener('submit', async function(event) {
        event.preventDefault();

        const formData = new FormData(event.target);
        const body = JSON.stringify({
            emailAddress: formData.get('emailAddress')
        });

        showLoading(true);
        hideError(document.getElementById('error'));

        try {
            const url = AppConfig.apiUrl(AppConfig.API_PATHS.AUTH_FORGOT_PASSWORD);
            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body
            });

            showLoading(false);

            if (!response.ok) {
                const errorEl = document.getElementById('error');
                if (errorEl) {
                    errorEl.textContent = 'Unable to process request. Please try again.';
                    errorEl.style.display = 'block';
                }
                return;
            }

            showSuccess('If an account exists for that email, a password reset link has been sent.');
            form.reset();
        } catch (e) {
            showLoading(false);
            const errorEl = document.getElementById('error');
            if (errorEl) {
                errorEl.textContent = 'Unable to process request. Please try again.';
                errorEl.style.display = 'block';
            }
        }
    });
});
