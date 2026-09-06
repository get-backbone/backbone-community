// Job content toggle functionality
document.addEventListener('DOMContentLoaded', function() {
  // Check authentication before proceeding
  if (!AuthUtils.requireAuth()) {
    return; // Redirected to login
  }
  
  const toggleButton = document.getElementById('jobContentToggle');
  const expandedContent = document.getElementById('jobContentExpanded');
  
  if (toggleButton && expandedContent) {
    toggleButton.addEventListener('click', function() {
      expandedContent.classList.toggle('show');
    });
  }
});

