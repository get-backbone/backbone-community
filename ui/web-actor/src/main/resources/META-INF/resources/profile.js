// Load and display user profile on page load
window.addEventListener('DOMContentLoaded', async function() {
    const loadingDiv = document.getElementById('loading');
    const errorDiv = document.getElementById('error');
    const profileDiv = document.getElementById('profile');

    // Show loading state
    if (loadingDiv) {
        loadingDiv.classList.add('show');
    }
    if (errorDiv) {
        errorDiv.classList.remove('show');
    }

    // Check authentication before proceeding
    if (!AuthUtils.requireAuth()) {
        return; // Redirected to login
    }

    try {
        console.log('Fetching HAL actor profile');

        const profileData = await ActorSession.load(true);

        // Hide loading
        if (loadingDiv) {
            loadingDiv.classList.remove('show');
        }

        if (!profileData) {
            if (errorDiv) {
                showError(errorDiv, 'Unable to load actor profile.');
            }
            return;
        }
        
        displayProfile(profileData, profileDiv);
        
        // Update header after profile is loaded (header manages its own display)
        if (typeof updateHeaderNavigation === 'function') {
            checkAuthStatus().then(authStatus => {
                updateHeaderNavigation(authStatus);
            });
        }
    } catch (error) {
        console.error('Error fetching profile:', error);
        if (loadingDiv) {
            loadingDiv.classList.remove('show');
        }
        if (errorDiv) {
            showError(errorDiv, 'Failed to load profile: ' + error.message);
        }
    }
});

function displayProfile(profile, profileDiv) {
    if (!profileDiv) {
        return;
    }

    let html = '<div class="profile-section">';
    html += '<h2>Candidate Information</h2>';
    html += '<div class="profile-details">';
    
    if (profile.username) {
        html += `<div class="profile-item"><strong>Name:</strong> ${escapeHtml(profile.username)}</div>`;
    }
    if (profile.emailAddress) {
        html += `<div class="profile-item"><strong>Email:</strong> ${escapeHtml(profile.emailAddress)}</div>`;
    }
    if (profile.timestamp) {
        html += `<div class="profile-item"><strong>Registered:</strong> ${new Date(profile.timestamp).toLocaleString()}</div>`;
    }
    
    html += '</div>';
    html += '</div>';

    // Resume section
    if (profile.transactionId || profile.formattedName || profile.professionalSummary) {
        html += '<div class="profile-section">';
        html += '<h2>Resume Information</h2>';
        html += '<div class="profile-details">';
        
        if (profile.formattedName) {
            html += `<div class="profile-item"><strong>Name from Resume:</strong> ${escapeHtml(profile.formattedName)}</div>`;
        }
        if (profile.parseTimestamp) {
            html += `<div class="profile-item"><strong>Parsed:</strong> ${new Date(profile.parseTimestamp).toLocaleString()}</div>`;
        }
        if (profile.transactionId) {
            html += `<div class="profile-item"><strong>Transaction ID:</strong> <span style="font-family: monospace; font-size: 0.85rem; color: var(--text-muted);">${escapeHtml(profile.transactionId)}</span></div>`;
        }
        if (profile.resumeUploadKey) {
            // Construct S3 URL - LocalStack format for now, can be updated for AWS
            // LocalStack: http://localhost:4566/{bucket}/{key}
            // AWS: https://{bucket}.s3.amazonaws.com/{key} or https://{bucket}.s3.{region}.amazonaws.com/{key}
            const bucketName = 'backbone-documents';
            const s3Url = `http://localhost:4566/${bucketName}/${escapeHtml(profile.resumeUploadKey)}`;
            
            // Truncate the key part for display: show first 5 chars and last 10 chars
            const key = profile.resumeUploadKey;
            const truncatedKey = key.length > 15 
                ? `${key.substring(0, 5)}...${key.substring(key.length - 10)}`
                : key;
            const truncatedUrl = `http://localhost:4566/${bucketName}/${truncatedKey}`;
            
            html += `<div class="profile-item"><strong>Resume Download:</strong> <a href="${s3Url}" target="_blank" style="display: inline-flex; align-items: center; gap: 6px;"><span style="font-size: 1rem;">⬇️</span>${truncatedUrl}</a></div>`;
        }
        if (profile.professionalSummary) {
            html += '<div class="profile-item" style="border-bottom: none; padding-bottom: 0;"><strong>Professional Summary:</strong></div>';
            html += '<div class="resume-data">';
            // Display professional summary as formatted text (preserve line breaks)
            const formattedSummary = escapeHtml(profile.professionalSummary).replace(/\n/g, '<br>');
            html += `<div class="resume-data-content" style="white-space: pre-wrap;">${formattedSummary}</div>`;
            html += '</div>';
        }
        // Note: resumeData field is kept for backward compatibility but not displayed
        
        html += '</div>';
        html += '</div>';
    } else {
        html += '<div class="profile-section">';
        html += '<h2>Resume Information</h2>';
        html += '<p style="color: var(--text-muted); margin: 0;">No resume uploaded yet.</p>';
        html += '</div>';
    }

    profileDiv.innerHTML = html;
}

