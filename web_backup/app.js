// Selvi's Beauty Parlour - Core Application Logic
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";
import { firebaseConfig, isFirebaseConfigured } from "./firebase-config.js";

let firebaseApp = null;
let auth = null;

if (isFirebaseConfigured()) {
  firebaseApp = initializeApp(firebaseConfig);
  auth = getAuth(firebaseApp);
  
  // Auth state observer
  onAuthStateChanged(auth, (user) => {
    if (user) {
      // Find or create customer matching user.email in local customers list
      const customers = getCustomers();
      let customer = customers.find(c => c.email.toLowerCase() === user.email.toLowerCase());
      if (!customer) {
        const name = user.displayName || user.email.split('@')[0];
        customer = {
          id: `cust-${user.uid}`,
          name: name.charAt(0).toUpperCase() + name.slice(1),
          badge: "Occasional",
          memberSince: "Jul 2026",
          phone: "+91 1234567890",
          email: user.email,
          birthday: "Jan 01",
          skinType: "Normal",
          hairType: "Straight",
          preferredTech: "Selvi",
          points: 0,
          reliability: 100,
          hospitalityRating: 100,
          cancellations: 0,
          privateNote: "Created via Firebase Auth session."
        };
        customers.push(customer);
        setCustomers(customers);
      }
      setCurrentUser(customer);
      
      // If currently on onboarding page, redirect to dashboard
      const hash = window.location.hash;
      if (hash === '#customer/login' || hash === '#customer/signup' || hash === '#customer/get-started') {
        window.location.hash = '#customer/dashboard';
      }
    }
  });
}

// Temporary booking state during customer booking funnel
let tempBooking = {
  serviceId: null,
  occasion: 'selfcare',
  date: '2026-07-13', // default selected date
  time: '11:00 AM', // default selected time
  loyaltyDiscount: 0,
  pointsApplied: 0,
  paymentMethod: 'Credit Card **** 4242'
};

// Timer state for "Happening Now"
let timerState = {
  totalSeconds: 12 * 60 + 45, // 12 minutes 45 seconds default
  currentSeconds: 12 * 60 + 45,
  intervalId: null,
  activeClient: "Monica Bellucci",
  activeService: "Hair Colouring"
};

// Current active perspective: 'customer' or 'owner'
let currentPerspective = 'customer';

// Initial Route setup
window.addEventListener('hashchange', router);
window.addEventListener('DOMContentLoaded', () => {
  // Set default view on load if none exists
  if (!window.location.hash) {
    window.location.hash = '#customer/get-started';
  } else {
    router();
  }
  
  // Start the background timer for happening now
  startLiveTimer();
});

// Switch perspective (Customer <-> Owner)
function switchPerspective(perspective) {
  currentPerspective = perspective;
  
  // Update toggle bar buttons
  const btnCustomer = document.getElementById('btn-switch-customer');
  const btnOwner = document.getElementById('btn-switch-owner');
  const label = document.getElementById('current-perspective-label');
  
  if (perspective === 'customer') {
    btnCustomer.classList.add('active');
    btnOwner.classList.remove('active');
    label.innerText = 'Customer App';
    window.location.hash = '#customer/dashboard';
  } else {
    btnCustomer.classList.remove('active');
    btnOwner.classList.add('active');
    label.innerText = 'Owner/Staff View';
    window.location.hash = '#owner/dashboard';
  }
}

// Router
function router() {
  const hash = window.location.hash || '#customer/get-started';
  const content = document.getElementById('screen-content');
  
  // Hide container scroll momentarily for clean transition
  content.scrollTop = 0;
  
  // Route matching
  if (hash.startsWith('#customer/get-started')) {
    content.innerHTML = renderGetStarted();
  } else if (hash.startsWith('#customer/login')) {
    content.innerHTML = renderLogin();
  } else if (hash.startsWith('#customer/signup')) {
    content.innerHTML = renderSignUp();
  } else if (hash.startsWith('#customer/forgot-password')) {
    content.innerHTML = renderForgotPassword();
  } else if (hash.startsWith('#customer/dashboard')) {
    content.innerHTML = renderCustomerDashboard();
  } else if (hash.startsWith('#customer/services')) {
    content.innerHTML = renderServices();
  } else if (hash.startsWith('#customer/book-appointment')) {
    content.innerHTML = renderBookAppointment();
    setupCalendar();
  } else if (hash.startsWith('#customer/loyalty')) {
    content.innerHTML = renderLoyaltyOffers();
  } else if (hash.startsWith('#customer/checkout')) {
    content.innerHTML = renderCheckoutReward();
  } else if (hash.startsWith('#customer/payment-confirm')) {
    content.innerHTML = renderPaymentConfirmation();
  } else if (hash.startsWith('#customer/appointments')) {
    const params = new URLSearchParams(hash.split('?')[1]);
    const tab = params.get('tab') || 'upcoming';
    content.innerHTML = renderAppointmentHistory(tab);
  } else if (hash.startsWith('#customer/profile')) {
    content.innerHTML = renderUserProfile();
  } 
  
  // Owner Routes
  else if (hash.startsWith('#owner/dashboard')) {
    content.innerHTML = renderOwnerDashboard();
  } else if (hash.startsWith('#owner/happening-now')) {
    content.innerHTML = renderHappeningNow();
    setupTimerSVG();
  } else if (hash.startsWith('#owner/requests')) {
    const params = new URLSearchParams(hash.split('?')[1]);
    const tab = params.get('tab') || 'pending';
    content.innerHTML = renderAppointmentRequests(tab);
  } else if (hash.startsWith('#owner/schedule')) {
    content.innerHTML = renderMasterSchedule();
  } else if (hash.startsWith('#owner/services')) {
    content.innerHTML = renderManageServices();
  } else if (hash.startsWith('#owner/directory')) {
    content.innerHTML = renderCustomerDirectory();
  } else if (hash.startsWith('#owner/profile')) {
    const params = new URLSearchParams(hash.split('?')[1]);
    const id = params.get('id') || 'cust-monica';
    content.innerHTML = renderOwnerCustomerProfile(id);
  } else {
    // Fallback
    content.innerHTML = renderGetStarted();
  }
  
  // Render Lucide icons
  if (typeof lucide !== 'undefined') {
    lucide.createIcons();
  }
  
  // Sync the perspective indicator at the top
  const btnCustomer = document.getElementById('btn-switch-customer');
  const btnOwner = document.getElementById('btn-switch-owner');
  const label = document.getElementById('current-perspective-label');
  
  if (hash.startsWith('#owner/')) {
    currentPerspective = 'owner';
    btnCustomer.classList.remove('active');
    btnOwner.classList.add('active');
    label.innerText = 'Owner/Staff View';
  } else {
    currentPerspective = 'customer';
    btnCustomer.classList.add('active');
    btnOwner.classList.remove('active');
    label.innerText = 'Customer App';
  }
}

// ----------------------------------------------------
// CUSTOMER SCREENS RENDERERS
// ----------------------------------------------------

function renderGetStarted() {
  return `
    <div class="animated-screen padded-container" style="justify-content: space-between; padding: 40px 20px; background: linear-gradient(180deg, rgba(74, 21, 37, 0.95) 0%, rgba(32, 5, 13, 0.98) 100%); color: #FFFFFF; text-align: center;">
      <div style="flex: 1; display: flex; flex-direction: column; justify-content: center; align-items: center; gap: 16px;">
        <div class="signup-logo-icon" style="background: rgba(255, 107, 139, 0.2); border: 2px solid var(--primary); color: #FFFFFF; font-size: 36px; width: 80px; height: 80px; box-shadow: 0 0 20px rgba(255, 107, 139, 0.4);">S</div>
        <h1 class="signup-title" style="color: #FFFFFF; font-size: 26px;">Selvi's Beauty Parlour</h1>
        <p style="font-size: 13px; opacity: 0.8; max-width: 80%; line-height: 1.5;">Experience premium organic treatments, professional diagnostics, and custom hairstyling tailored specifically for you.</p>
      </div>
      
      <div style="width: 100%;">
        <button class="btn-primary" onclick="window.location.hash='#customer/login'" style="background: var(--primary); border: none; box-shadow: 0 6px 20px rgba(255, 107, 139, 0.4);">
          Get Started <i data-lucide="sparkles"></i>
        </button>
      </div>
    </div>
  `;
}

let activeLoginRole = 'customer';

function selectLoginRole(role) {
  activeLoginRole = role;
  
  const custBtn = document.getElementById('login-role-customer');
  const ownerBtn = document.getElementById('login-role-owner');
  const usernameInput = document.getElementById('login-username-input');
  
  if (role === 'customer') {
    custBtn.classList.add('active');
    ownerBtn.classList.remove('active');
    if (usernameInput) usernameInput.value = 'Monica Bellucci';
  } else {
    custBtn.classList.remove('active');
    ownerBtn.classList.add('active');
    if (usernameInput) usernameInput.value = 'Selvi (Owner)';
  }
}

function renderLogin() {
  // Reset selected login role when page renders
  activeLoginRole = 'customer';
  
  return `
    <div class="animated-screen padded-container" style="justify-content: center;">
      <div class="signup-brand-logo">
        <div class="signup-logo-icon">S</div>
        <div class="signup-title">Selvi's Beauty Parlour</div>
        <div class="signup-subtitle">Experience Luxury Hair, Nails & Skin Treatment</div>
      </div>
      
      <!-- Role Selector Segmented Control -->
      <div class="form-group">
        <label class="form-label">Select Portal</label>
        <div class="occasion-capsules" style="margin-bottom: 12px; display: flex; gap: 8px;">
          <div class="occasion-capsule active" id="login-role-customer" onclick="selectLoginRole('customer')" style="flex: 1; padding: 10px; cursor: pointer; border-radius: var(--radius-md); text-align: center; border: 1.5px solid var(--border-color);">
            <span class="occasion-icon">👤</span>
            <span class="occasion-label" style="font-size: 10px; font-weight: 600; display: block; margin-top: 4px;">Customer</span>
          </div>
          <div class="occasion-capsule" id="login-role-owner" onclick="selectLoginRole('owner')" style="flex: 1; padding: 10px; cursor: pointer; border-radius: var(--radius-md); text-align: center; border: 1.5px solid var(--border-color);">
            <span class="occasion-icon">💼</span>
            <span class="occasion-label" style="font-size: 10px; font-weight: 600; display: block; margin-top: 4px;">Owner/Staff</span>
          </div>
        </div>
      </div>
      
      <div class="form-group">
        <label class="form-label">Username / Phone Number</label>
        <input type="text" class="form-input" id="login-username-input" placeholder="Enter username or phone" value="">
      </div>
      
      <div class="form-group" style="margin-bottom: 10px;">
        <label class="form-label">Password</label>
        <input type="password" class="form-input" placeholder="Enter password" value="">
      </div>
      
      <div style="text-align: right; margin-bottom: 24px;">
        <span class="btn-text" onclick="window.location.hash='#customer/forgot-password'" style="font-size: 11px;">Forgot Password?</span>
      </div>
      
      <button class="btn-primary" onclick="executeLogin()">
        Log In <i data-lucide="log-in"></i>
      </button>
      
      <div class="social-login-container">
        <div class="social-login-text">OR Continue with</div>
        <div class="social-buttons">
          <button class="social-btn"><img src="https://cdn-icons-png.flaticon.com/512/2991/2991148.png" alt="Google"></button>
          <button class="social-btn"><img src="https://cdn-icons-png.flaticon.com/512/0/747.png" alt="Apple"></button>
          <button class="social-btn"><img src="https://cdn-icons-png.flaticon.com/512/124/124010.png" alt="Facebook"></button>
        </div>
      </div>
      
      <div class="signup-footer">
        Don't have an account? <span class="btn-text" onclick="window.location.hash='#customer/signup'">Sign Up</span>
      </div>
    </div>
  `;
}

function executeLogin() {
  const username = document.getElementById('login-username-input').value.trim();
  const password = "password123"; // default fallback password for quick demo credentials
  
  if (activeLoginRole === 'customer') {
    if (isFirebaseConfigured() && auth) {
      const email = username.includes('@') ? username : `${username.toLowerCase().replace(/\s+/g, '')}@example.com`;
      signInWithEmailAndPassword(auth, email, password)
        .then((userCredential) => {
          console.log("Logged in via Firebase:", userCredential.user);
          // Redirection will be handled automatically by onAuthStateChanged observer
        })
        .catch((error) => {
          alert(`Firebase Login Error: ${error.message}\n(Falling back to offline mock authentication)`);
          // Offline fallback
          mockOfflineLogin(username);
        });
    } else {
      mockOfflineLogin(username);
    }
  } else {
    // Owner perspective
    switchPerspective('owner');
    window.location.hash = '#owner/dashboard';
  }
}

function mockOfflineLogin(username) {
  if (username) {
    const customers = getCustomers();
    let user = customers.find(c => c.name.toLowerCase() === username.toLowerCase() || c.phone === username);
    if (!user) {
      user = {
        id: `cust-${Date.now()}`,
        name: username,
        badge: "Occasional",
        memberSince: "Jul 2026",
        phone: "+91 1234567890",
        email: `${username.toLowerCase().replace(/\s+/g, '')}@example.com`,
        birthday: "Jan 01",
        skinType: "Normal",
        hairType: "Straight",
        preferredTech: "Selvi",
        points: 0,
        reliability: 100,
        hospitalityRating: 100,
        cancellations: 0,
        privateNote: "New client logged in via web portal."
      };
      customers.push(user);
      setCustomers(customers);
    }
    setCurrentUser(user);
  }
  window.location.hash = '#customer/dashboard';
}

let activeSignupRole = 'customer';

function selectSignupRole(role) {
  activeSignupRole = role;
  
  const custBtn = document.getElementById('signup-role-customer');
  const ownerBtn = document.getElementById('signup-role-owner');
  
  if (role === 'customer') {
    custBtn.classList.add('active');
    ownerBtn.classList.remove('active');
  } else {
    custBtn.classList.remove('active');
    ownerBtn.classList.add('active');
  }
}

function renderSignUp() {
  activeSignupRole = 'customer';
  
  return `
    <div class="animated-screen padded-container" style="justify-content: center;">
      <div class="signup-brand-logo">
        <div class="signup-logo-icon">S</div>
        <div class="signup-title">Selvi's Beauty Parlour</div>
        <div class="signup-subtitle">Experience Luxury Hair, Nails & Skin Treatment</div>
      </div>
      
      <!-- Role Selector Segmented Control -->
      <div class="form-group">
        <label class="form-label">Sign Up As</label>
        <div class="occasion-capsules" style="margin-bottom: 12px; display: flex; gap: 8px;">
          <div class="occasion-capsule active" id="signup-role-customer" onclick="selectSignupRole('customer')" style="flex: 1; padding: 10px; cursor: pointer; border-radius: var(--radius-md); text-align: center; border: 1.5px solid var(--border-color);">
            <span class="occasion-icon">👤</span>
            <span class="occasion-label" style="font-size: 10px; font-weight: 600; display: block; margin-top: 4px;">Customer</span>
          </div>
          <div class="occasion-capsule" id="signup-role-owner" onclick="selectSignupRole('owner')" style="flex: 1; padding: 10px; cursor: pointer; border-radius: var(--radius-md); text-align: center; border: 1.5px solid var(--border-color);">
            <span class="occasion-icon">💼</span>
            <span class="occasion-label" style="font-size: 10px; font-weight: 600; display: block; margin-top: 4px;">Owner/Staff</span>
          </div>
        </div>
      </div>
      
      <div class="form-group">
        <label class="form-label">Username</label>
        <input type="text" class="form-input" id="signup-username-input" placeholder="Enter your username" value="">
      </div>
      
      <div class="form-group">
        <label class="form-label">Phone Number</label>
        <input type="text" class="form-input" id="signup-phone-input" placeholder="Enter your phone number" value="">
      </div>
      
      <div class="form-group">
        <label class="form-label">Password</label>
        <input type="password" class="form-input" placeholder="Create password" value="">
      </div>
      
      <div class="form-group" style="margin-bottom: 24px;">
        <label class="form-label">Confirm Password</label>
        <input type="password" class="form-input" placeholder="Confirm password" value="">
      </div>
      
      <button class="btn-primary" onclick="executeSignUp()">
        Create Account <i data-lucide="arrow-right"></i>
      </button>
      
      <div class="social-login-container">
        <div class="social-login-text">OR Continue with</div>
        <div class="social-buttons">
          <button class="social-btn"><img src="https://cdn-icons-png.flaticon.com/512/2991/2991148.png" alt="Google"></button>
          <button class="social-btn"><img src="https://cdn-icons-png.flaticon.com/512/0/747.png" alt="Apple"></button>
          <button class="social-btn"><img src="https://cdn-icons-png.flaticon.com/512/124/124010.png" alt="Facebook"></button>
        </div>
      </div>
      
      <div class="signup-footer">
        Already have an account? <span class="btn-text" onclick="window.location.hash='#customer/login'">Login</span>
      </div>
    </div>
  `;
}

function executeSignUp() {
  const username = document.getElementById('signup-username-input').value.trim() || "Monica Bellucci";
  const phone = document.getElementById('signup-phone-input').value.trim() || "+91 1234567890";
  const password = "password123";
  const email = `${username.toLowerCase().replace(/\s+/g, '')}@example.com`;
  
  if (activeSignupRole === 'customer') {
    if (isFirebaseConfigured() && auth) {
      createUserWithEmailAndPassword(auth, email, password)
        .then((userCredential) => {
          console.log("Registered via Firebase:", userCredential.user);
          // Create customer profile mapping in local data structure
          const customers = getCustomers();
          const user = {
            id: `cust-${userCredential.user.uid}`,
            name: username,
            badge: "Punctual",
            memberSince: "Jul 2026",
            phone: phone,
            email: email,
            birthday: "Jan 14",
            skinType: "Sensitive, Dry",
            hairType: "Curly, 3B",
            preferredTech: "Selvi",
            points: 200,
            reliability: 100,
            hospitalityRating: 100,
            cancellations: 0,
            privateNote: "Registered via Firebase Auth."
          };
          customers.push(user);
          setCustomers(customers);
          setCurrentUser(user);
          // Redirection will trigger from auth listener
        })
        .catch((error) => {
          alert(`Firebase Register Error: ${error.message}\n(Falling back to offline mock signup)`);
          mockOfflineSignUp(username, phone, email);
        });
    } else {
      mockOfflineSignUp(username, phone, email);
    }
  } else {
    // Owner registered
    switchPerspective('owner');
    window.location.hash = '#owner/dashboard';
  }
}

function mockOfflineSignUp(username, phone, email) {
  const customers = getCustomers();
  let user = customers.find(c => c.name.toLowerCase() === username.toLowerCase() || c.phone === phone);
  if (!user) {
    user = {
      id: `cust-${Date.now()}`,
      name: username,
      badge: "Punctual",
      memberSince: "Jul 2026",
      phone: phone,
      email: email,
      birthday: "Jan 14",
      skinType: "Sensitive, Dry",
      hairType: "Curly, 3B",
      preferredTech: "Selvi",
      points: 200,
      reliability: 100,
      hospitalityRating: 100,
      cancellations: 0,
      privateNote: "Registered via offline portal."
    };
    customers.push(user);
    setCustomers(customers);
  }
  setCurrentUser(user);
  window.location.hash = '#customer/dashboard';
}

function renderForgotPassword() {
  return `
    <div class="animated-screen padded-container" style="justify-content: center;">
      <div class="signup-brand-logo">
        <div class="signup-logo-icon"><i data-lucide="lock"></i></div>
        <div class="signup-title" style="margin-top: 10px;">Forgot Password?</div>
        <div class="signup-subtitle" style="margin-top: 4px;">Enter your email to receive recovery instructions</div>
      </div>
      
      <div class="form-group" style="margin-bottom: 24px;">
        <label class="form-label">Email Address</label>
        <input type="email" class="form-input" placeholder="Enter your email" value="example@gmail.com">
      </div>
      
      <button class="btn-primary" onclick="alert('Recovery instructions sent to email!'); window.location.hash='#customer/login'">
        Reset Password
      </button>
      
      <div class="signup-footer" style="margin-top: 24px;">
        Remembered your details? <span class="btn-text" onclick="window.location.hash='#customer/login'">Go back</span>
      </div>
    </div>
  `;
}

function renderCustomerDashboard() {
  const user = getCurrentUser();
  const bookings = getBookings().filter(b => b.customerName === user.name && b.status === "Confirmed");
  
  let nextVisitHTML = '';
  if (bookings.length > 0) {
    const nextBook = bookings[0];
    nextVisitHTML = `
      <div class="section-header">
        <div class="section-title">Your Next Visit</div>
        <span class="section-link" onclick="window.location.hash='#customer/appointments'">Manage</span>
      </div>
      <div class="next-visit-card" onclick="window.location.hash='#customer/appointments'">
        <div class="next-visit-info">
          <div class="next-visit-service">${nextBook.serviceName}</div>
          <div class="next-visit-time">
            <i data-lucide="calendar"></i> ${formatDisplayDate(nextBook.date)} at ${nextBook.time}
          </div>
        </div>
        <span class="badge badge-success">Upcoming</span>
      </div>
    `;
  } else {
    nextVisitHTML = `
      <div class="next-visit-card" style="justify-content: center; padding: 24px;" onclick="window.location.hash='#customer/services'">
        <div class="next-visit-info" style="align-items: center; gap: 8px;">
          <div class="next-visit-service" style="color: var(--light-text);">No upcoming visits scheduled</div>
          <span class="btn-text">Book your first slot</span>
        </div>
      </div>
    `;
  }
  
  // Show active delay banner if next booking has a delay
  let delayBannerHTML = '';
  if (bookings.length > 0 && bookings[0].liveStatus && bookings[0].liveStatus.hasDelay) {
    const live = bookings[0].liveStatus;
    delayBannerHTML = `
      <div class="live-status-banner" onclick="window.location.hash='#customer/appointments'">
        <div class="live-pulse-container">
          <div class="live-pulse-dot"></div>
        </div>
        <div class="live-status-text">
          <div class="live-status-title">Stylist Live Delay Alert</div>
          Your stylist ${bookings[0].stylist} is finishing up a previous service. New Start Time: <strong>${live.adjustedTime}</strong> (${live.delayMinutes} Mins Delay).
        </div>
      </div>
    `;
  }

  // Get active services from local state for recommended section
  const recommendedServices = getServices().slice(0, 2);

  return `
    <div class="animated-screen">
      <div class="padded-container">
        <!-- Greetings header -->
        <div class="welcome-section">
          <div>
            <div class="welcome-text">Hello, Beautiful</div>
            <div class="welcome-desc">Welcome back to your luxury sanctuary</div>
          </div>
          <button class="icon-btn" onclick="window.location.hash='#customer/profile'"><i data-lucide="user"></i></button>
        </div>
        
        <!-- Live Status Alerts -->
        ${delayBannerHTML}
        
        <!-- Hero booking card -->
        <div class="banner-booking-card">
          <div class="banner-title">Premium Salon Care</div>
          <div class="banner-desc">Pamper yourself with state of the art skincare, customized haircuts, and nail spas designed by Selvi.</div>
          <button class="btn-banner" onclick="window.location.hash='#customer/services'">
            Book Appointment <i data-lucide="sparkles"></i>
          </button>
        </div>
        
        <!-- Next Visit -->
        ${nextVisitHTML}
        
        <!-- Quick Nav Grid -->
        <div class="grid-2x2">
          <div class="grid-card" onclick="window.location.hash='#customer/services'">
            <div class="grid-card-icon"><i data-lucide="scissors"></i></div>
            <div class="grid-card-title">Our Services</div>
            <div class="grid-card-desc">24 premium packages</div>
          </div>
          <div class="grid-card" onclick="window.location.hash='#customer/loyalty'">
            <div class="grid-card-icon" style="background-color: #FFF8E7; color: #FFB627;"><i data-lucide="gift"></i></div>
            <div class="grid-card-title">Gift Cards</div>
            <div class="grid-card-desc">Redeem loyalty points</div>
          </div>
        </div>
        
        <!-- Recommended Section -->
        <div class="section-header">
          <div class="section-title">Recommended For You</div>
        </div>
        
        <div class="horizontal-list">
          ${recommendedServices.map(svc => `
            <div class="recommended-card">
              <img class="recommended-img" src="${svc.image}" alt="${svc.name}">
              <div class="recommended-name">${svc.name}</div>
              <div class="recommended-footer">
                <span class="recommended-price">Rs. ${svc.price}</span>
                <button class="recommended-btn" onclick="startBooking('${svc.id}')">Book</button>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
      
      <!-- Footer Nav -->
      ${renderCustomerBottomNav('home')}
    </div>
  `;
}

function renderServices() {
  const services = getServices().filter(s => s.active);
  const categories = ["All", ...new Set(services.map(s => s.category))];
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Selvi's Menu</span>
          <h1 class="header-title">Our Services</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#customer/dashboard'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <!-- Search -->
        <div class="search-bar-container">
          <i data-lucide="search"></i>
          <input type="text" id="service-search-input" class="search-input" placeholder="Search for treatments, cuts..." oninput="filterServices()">
        </div>
        
        <!-- Category Pills -->
        <div class="category-pills">
          ${categories.map((cat, idx) => `
            <button class="pill ${idx === 0 ? 'active' : ''}" onclick="filterByCategory(this, '${cat}')">${cat}</button>
          `).join('')}
        </div>
        
        <!-- Service List -->
        <div class="service-list" id="services-list-container">
          ${renderServicesSubList(services)}
        </div>
      </div>
      
      ${renderCustomerBottomNav('services')}
    </div>
  `;
}

function renderServicesSubList(services) {
  return services.map(svc => `
    <div class="service-card" data-category="${svc.category}">
      <img class="service-img" src="${svc.image}" alt="${svc.name}">
      <div class="service-details">
        <div class="service-header-row">
          <div class="service-name">${svc.name}</div>
        </div>
        <div class="service-meta">${svc.duration} Mins | With Stylist</div>
        <p class="service-description">${svc.description}</p>
        <div class="service-price-btn-row">
          <span class="service-price">Rs. ${svc.price}</span>
          <button class="btn-book-service" onclick="startBooking('${svc.id}')">Book Now</button>
        </div>
      </div>
    </div>
  `).join('');
}

// Function triggered when booking is initiated
function startBooking(serviceId) {
  tempBooking.serviceId = serviceId;
  tempBooking.loyaltyDiscount = 0;
  tempBooking.pointsApplied = 0;
  window.location.hash = '#customer/book-appointment';
}

// Service page filters
function filterServices() {
  const query = document.getElementById('service-search-input').value.toLowerCase();
  const cards = document.querySelectorAll('.service-card');
  cards.forEach(card => {
    const name = card.querySelector('.service-name').innerText.toLowerCase();
    const desc = card.querySelector('.service-description').innerText.toLowerCase();
    if (name.includes(query) || desc.includes(query)) {
      card.style.display = 'flex';
    } else {
      card.style.display = 'none';
    }
  });
}

function filterByCategory(btn, category) {
  // Toggle active class
  document.querySelectorAll('.category-pills .pill').forEach(p => p.classList.remove('active'));
  btn.classList.add('active');
  
  const cards = document.querySelectorAll('.service-card');
  cards.forEach(card => {
    if (category === 'All' || card.getAttribute('data-category') === category) {
      card.style.display = 'flex';
    } else {
      card.style.display = 'none';
    }
  });
}

function renderBookAppointment() {
  const services = getServices();
  const selectedSvc = services.find(s => s.id === tempBooking.serviceId) || services[0];
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Schedule visit</span>
          <h1 class="header-title">Book Appointment</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#customer/services'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <!-- Occasion Select -->
        <div class="time-grid-label">What's the occasion?</div>
        <div class="occasion-capsules">
          <div class="occasion-capsule ${tempBooking.occasion === 'selfcare' ? 'active' : ''}" onclick="selectOccasion(this, 'selfcare')">
            <span class="occasion-icon">🌸</span>
            <span class="occasion-label">Selfcare</span>
          </div>
          <div class="occasion-capsule ${tempBooking.occasion === 'bridal' ? 'active' : ''}" onclick="selectOccasion(this, 'bridal')">
            <span class="occasion-icon">💖</span>
            <span class="occasion-label">Bridal</span>
          </div>
          <div class="occasion-capsule ${tempBooking.occasion === 'party' ? 'active' : ''}" onclick="selectOccasion(this, 'party')">
            <span class="occasion-icon">🎉</span>
            <span class="occasion-label">Party</span>
          </div>
        </div>
        
        <!-- Selected Service Details -->
        <div class="time-grid-label">Selected Service</div>
        <div class="summary-service-card" style="margin-bottom: 20px;">
          <img class="service-img" src="${selectedSvc.image}" style="width: 50px; height: 50px;">
          <div class="summary-service-details">
            <div class="service-name">${selectedSvc.name}</div>
            <div class="service-meta">${selectedSvc.duration} Mins | Rs. ${selectedSvc.price}</div>
          </div>
        </div>
        
        <!-- Calendar -->
        <div class="time-grid-label">Pick a date</div>
        <div class="calendar-container">
          <div class="calendar-header">
            <button class="calendar-nav-btn" onclick="adjustCalendarMonth(-1)"><i data-lucide="chevron-left"></i></button>
            <div class="calendar-month" id="calendar-month-year-label">October 2026</div>
            <button class="calendar-nav-btn" onclick="adjustCalendarMonth(1)"><i data-lucide="chevron-right"></i></button>
          </div>
          <div class="calendar-weekdays">
            <span>S</span><span>M</span><span>T</span><span>W</span><span>T</span><span>F</span><span>S</span>
          </div>
          <div class="calendar-grid" id="calendar-days-grid">
            <!-- Rendered by calendar JS setup -->
          </div>
        </div>
        
        <!-- Available Times -->
        <div class="time-picker-section">
          <div class="time-grid-label">Morning Slots</div>
          <div class="time-slots-grid">
            <div class="time-slot ${tempBooking.time === '10:00 AM' ? 'active' : ''}" onclick="selectTimeSlot(this, '10:00 AM')">10:00 AM</div>
            <div class="time-slot ${tempBooking.time === '11:00 AM' ? 'active' : ''}" onclick="selectTimeSlot(this, '11:00 AM')">11:00 AM</div>
            <div class="time-slot ${tempBooking.time === '11:45 AM' ? 'active' : ''}" onclick="selectTimeSlot(this, '11:45 AM')">11:45 AM</div>
          </div>
          
          <div class="time-grid-label">Afternoon Slots</div>
          <div class="time-slots-grid">
            <div class="time-slot ${tempBooking.time === '01:30 PM' ? 'active' : ''}" onclick="selectTimeSlot(this, '01:30 PM')">01:30 PM</div>
            <div class="time-slot ${tempBooking.time === '02:30 PM' ? 'active' : ''}" onclick="selectTimeSlot(this, '02:30 PM')">02:30 PM</div>
            <div class="time-slot ${tempBooking.time === '04:00 PM' ? 'active' : ''}" onclick="selectTimeSlot(this, '04:00 PM')">04:00 PM</div>
          </div>
        </div>
        
        <button class="btn-primary" onclick="window.location.hash='#customer/loyalty'">
          Proceed to Checkout <i data-lucide="arrow-right"></i>
        </button>
      </div>
      
      ${renderCustomerBottomNav('bookings')}
    </div>
  `;
}

function selectOccasion(el, occasion) {
  document.querySelectorAll('.occasion-capsules .occasion-capsule').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  tempBooking.occasion = occasion;
}

function selectTimeSlot(el, time) {
  document.querySelectorAll('.time-slots-grid .time-slot').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
  tempBooking.time = time;
}

// Calendar Date Picker Rendering Helper
let calendarYear = 2026;
let calendarMonth = 9; // 9 = October (0-indexed)

function setupCalendar() {
  const grid = document.getElementById('calendar-days-grid');
  const label = document.getElementById('calendar-month-year-label');
  if (!grid || !label) return;
  
  // Format Month Year Label
  const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  label.innerText = `${monthNames[calendarMonth]} ${calendarYear}`;
  
  // Clear Grid
  grid.innerHTML = '';
  
  const firstDay = new Date(calendarYear, calendarMonth, 1).getDay();
  const totalDays = new Date(calendarYear, calendarMonth + 1, 0).getDate();
  
  // Empty slots for alignment
  for (let i = 0; i < firstDay; i++) {
    grid.innerHTML += `<span class="calendar-day empty"></span>`;
  }
  
  // Real Days
  for (let day = 1; day <= totalDays; day++) {
    const dateStr = `${calendarYear}-${String(calendarMonth + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const isActive = tempBooking.date === dateStr;
    const isToday = day === 10 && calendarMonth === 6; // Mock today
    
    grid.innerHTML += `
      <span class="calendar-day ${isActive ? 'active' : ''} ${isToday ? 'today' : ''}" 
            onclick="selectCalendarDate(this, '${dateStr}')">
        ${day}
      </span>
    `;
  }
}

function selectCalendarDate(el, dateStr) {
  document.querySelectorAll('#calendar-days-grid .calendar-day').forEach(d => d.classList.remove('active'));
  el.classList.add('active');
  tempBooking.date = dateStr;
}

function adjustCalendarMonth(offset) {
  calendarMonth += offset;
  if (calendarMonth < 0) {
    calendarMonth = 11;
    calendarYear--;
  } else if (calendarMonth > 11) {
    calendarMonth = 0;
    calendarYear++;
  }
  setupCalendar();
}

function renderLoyaltyOffers() {
  const user = getCurrentUser();
  const maxRedeemablePercent = Math.min(user.points, 150); // mock threshold points logic

  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Exclusive Points</span>
          <h1 class="header-title">Loyalty Rewards</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#customer/book-appointment'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <!-- Hero Points display -->
        <div class="loyalty-hero-card">
          <div class="welcome-desc" style="color: rgba(255,255,255,0.7)">Available Balance</div>
          <div style="font-size: 28px; font-weight: 700; margin: 4px 0;">${user.points} <span style="font-size: 14px; font-weight: 500;">Points</span></div>
          
          <div class="loyalty-progress-container">
            <div class="loyalty-progress-bar">
              <div class="loyalty-progress-fill" style="width: ${(user.points / 1000) * 100}%;"></div>
            </div>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 10px;">
            <span>${1000 - user.points} pts away from Platinum Status</span>
            <span>Platinum: 1000 pts</span>
          </div>
          
          <button class="btn-small-points" onclick="alert('Viewing points history...')">Points History</button>
        </div>
        
        <!-- Offers list -->
        <div class="time-grid-label">Exclusive Offers</div>
        <div class="loyalty-offers-list" style="margin-bottom: 24px;">
          <!-- Offer 1 -->
          <div class="loyalty-offer-item">
            <div class="offer-icon-wrapper"><i data-lucide="sparkles"></i></div>
            <div class="offer-text-info">
              <div class="offer-title">Free Scalp Massage</div>
              <div class="offer-pts">Cost: 200 Points</div>
            </div>
            ${user.points >= 200 ? 
              `<button class="btn-redeem" onclick="applyPointsReward(200, 50, 'Free Scalp Massage')">Redeem</button>` : 
              `<button class="btn-redeem locked"><i data-lucide="lock"></i> Locked</button>`
            }
          </div>
          
          <!-- Offer 2 -->
          <div class="loyalty-offer-item">
            <div class="offer-icon-wrapper"><i data-lucide="percent"></i></div>
            <div class="offer-text-info">
              <div class="offer-title">15% Off Any Service</div>
              <div class="offer-pts">Cost: 500 Points</div>
            </div>
            ${user.points >= 500 ? 
              `<button class="btn-redeem" onclick="applyPointsReward(500, 100, '15% Off Discount')">Redeem</button>` : 
              `<button class="btn-redeem locked"><i data-lucide="lock"></i> Locked</button>`
            }
          </div>
          
          <!-- Offer 3 -->
          <div class="loyalty-offer-item">
            <div class="offer-icon-wrapper locked"><i data-lucide="lock"></i></div>
            <div class="offer-text-info">
              <div class="offer-title">Manicure Upgrade</div>
              <div class="offer-pts">Cost: 1000 Points</div>
            </div>
            ${user.points >= 1000 ? 
              `<button class="btn-redeem" onclick="applyPointsReward(1000, 200, 'Manicure Upgrade')">Redeem</button>` : 
              `<button class="btn-redeem locked"><i data-lucide="lock"></i> Locked</button>`
            }
          </div>
        </div>
        
        <button class="btn-primary" onclick="window.location.hash='#customer/checkout'">
          Skip / Continue to Checkout <i data-lucide="arrow-right"></i>
        </button>
      </div>
      
      ${renderCustomerBottomNav('bookings')}
    </div>
  `;
}

function applyPointsReward(points, discount, rewardName) {
  tempBooking.pointsApplied = points;
  tempBooking.loyaltyDiscount = discount;
  alert(`Successfully applied: ${rewardName}! Rs. ${discount} discount will be subtracted at checkout.`);
  window.location.hash = '#customer/checkout';
}

function renderCheckoutReward() {
  const services = getServices();
  const selectedSvc = services.find(s => s.id === tempBooking.serviceId) || services[0];
  
  const subtotal = selectedSvc.price;
  const discount = tempBooking.loyaltyDiscount;
  const tax = parseFloat(((subtotal - discount) * 0.08).toFixed(2));
  const total = parseFloat((subtotal - discount + tax).toFixed(2));
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Review summary</span>
          <h1 class="header-title">Checkout & Pay</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#customer/loyalty'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <!-- Selected Service Row -->
        <div class="time-grid-label">Selected Service</div>
        <div class="summary-service-card">
          <img class="service-img" src="${selectedSvc.image}" style="width: 50px; height: 50px;">
          <div class="summary-service-details">
            <div class="service-name">${selectedSvc.name}</div>
            <div class="service-meta">${selectedSvc.duration} Mins | With ${selectedSvc.id === "svc-3" ? 'Selvi' : 'Stylist'}</div>
          </div>
          <button class="btn-text" onclick="window.location.hash='#customer/services'" style="font-size: 11px;">Edit</button>
        </div>
        
        <!-- Loyalty points toggle -->
        <div class="reward-toggle-card">
          <div class="toggle-info">
            <div style="font-size: 12px; font-weight: 600; color: var(--secondary);">Apply Loyalty Reward</div>
            <div style="font-size: 10px; color: var(--light-text);">${discount > 0 ? `Redeemed ${tempBooking.pointsApplied} pts for Rs. ${discount} off` : 'No points reward applied'}</div>
          </div>
          <label class="toggle-switch-wrapper">
            <input type="checkbox" id="loyalty-toggle-chk" ${discount > 0 ? 'checked' : ''} onchange="toggleDiscountState(this)">
            <span class="toggle-slider"></span>
          </label>
        </div>
        
        <!-- Payment Methods -->
        <div class="time-grid-label">Payment Method</div>
        <div class="payment-methods">
          <div class="payment-method-option ${tempBooking.paymentMethod === 'Credit Card **** 4242' ? 'selected' : ''}" onclick="selectPaymentOption(this, 'Credit Card **** 4242')">
            <div class="payment-option-left">
              <i data-lucide="credit-card"></i>
              <span>Credit Card **** 4242</span>
            </div>
            <span class="radio-dot"></span>
          </div>
          
          <div class="payment-method-option ${tempBooking.paymentMethod === 'Apple Pay' ? 'selected' : ''}" onclick="selectPaymentOption(this, 'Apple Pay')">
            <div class="payment-option-left">
              <i data-lucide="smartphone"></i>
              <span>Apple Pay</span>
            </div>
            <span class="radio-dot"></span>
          </div>
          
          <div class="payment-method-option ${tempBooking.paymentMethod === 'Pay at Salon' ? 'selected' : ''}" onclick="selectPaymentOption(this, 'Pay at Salon')">
            <div class="payment-option-left">
              <i data-lucide="home"></i>
              <span>Pay at Salon Counter</span>
            </div>
            <span class="radio-dot"></span>
          </div>
        </div>
        
        <!-- Costs Box -->
        <div class="receipt-summary">
          <div class="receipt-row">
            <span>Subtotal</span>
            <span>Rs. ${subtotal.toFixed(2)}</span>
          </div>
          ${discount > 0 ? `
            <div class="receipt-row discount">
              <span>Loyalty Points Applied</span>
              <span>-Rs. ${discount.toFixed(2)}</span>
            </div>
          ` : ''}
          <div class="receipt-row">
            <span>GST Tax (8%)</span>
            <span>Rs. ${tax.toFixed(2)}</span>
          </div>
          <div class="receipt-row total">
            <span>Total Amount</span>
            <span id="checkout-total-val">Rs. ${total.toFixed(2)}</span>
          </div>
        </div>
        
        <button class="btn-primary" onclick="executeBookingOrder(${subtotal}, ${discount}, ${tax}, ${total})">
          Pay & Confirm Booking
        </button>
      </div>
    </div>
  `;
}

function selectPaymentOption(el, method) {
  document.querySelectorAll('.payment-methods .payment-method-option').forEach(o => o.classList.remove('selected'));
  el.classList.add('selected');
  tempBooking.paymentMethod = method;
}

function toggleDiscountState(chk) {
  if (!chk.checked) {
    tempBooking.loyaltyDiscount = 0;
    tempBooking.pointsApplied = 0;
  } else {
    // Re-apply a default discount if checked
    const user = getCurrentUser();
    if (user.points >= 200) {
      tempBooking.pointsApplied = 200;
      tempBooking.loyaltyDiscount = 50;
    } else {
      chk.checked = false;
      alert("You need at least 200 points to apply a discount.");
      return;
    }
  }
  // Refresh page HTML
  document.getElementById('screen-content').innerHTML = renderCheckoutReward();
  if (typeof lucide !== 'undefined') lucide.createIcons();
}

function executeBookingOrder(subtotal, discount, tax, total) {
  const user = getCurrentUser();
  const services = getServices();
  const selectedSvc = services.find(s => s.id === tempBooking.serviceId) || services[0];
  
  // Deduct points if applied
  if (tempBooking.pointsApplied > 0) {
    user.points -= tempBooking.pointsApplied;
  }
  
  // Earn points (10% of subtotal)
  const earned = Math.floor(subtotal * 0.1);
  user.points += earned;
  
  // Update user state
  setCurrentUser(user);
  
  // Save booking
  const bookings = getBookings();
  const newBooking = {
    id: `bk-${Date.now()}`,
    customerName: user.name,
    customerPhone: user.phone,
    customerEmail: user.email,
    serviceName: selectedSvc.name,
    price: subtotal,
    duration: selectedSvc.duration,
    date: tempBooking.date,
    time: tempBooking.time,
    stylist: "Selvi",
    status: "Pending", // Owner needs to approve
    loyaltyDiscount: discount,
    tax: tax,
    totalPaid: total,
    pointsApplied: tempBooking.pointsApplied,
    pointsEarned: earned
  };
  
  bookings.push(newBooking);
  setBookings(bookings);
  
  // Navigate to confirmation screen
  window.location.hash = `#customer/payment-confirm?id=${newBooking.id}`;
}

function renderPaymentConfirmation() {
  const params = new URLSearchParams(window.location.hash.split('?')[1]);
  const bookingId = params.get('id');
  const booking = getBookings().find(b => b.id === bookingId) || getBookings()[0];
  
  return `
    <div class="animated-screen padded-container" style="justify-content: space-between;">
      <div style="display: flex; justify-content: flex-end; width: 100%;">
        <button class="icon-btn" onclick="window.location.hash='#customer/dashboard'"><i data-lucide="x"></i></button>
      </div>
      
      <div>
        <div class="confirm-circle-container">
          <div class="confirm-circle"><i data-lucide="check"></i></div>
          <div class="confirm-title">Thank You!</div>
          <div class="confirm-desc">Your appointment booking is successfully submitted. We will notify you once Selvi approves.</div>
        </div>
        
        <!-- Summary Card -->
        <div class="summary-box">
          <div class="summary-box-header">
            <span>${booking.serviceName}</span>
            <span>Rs. ${booking.totalPaid.toFixed(2)}</span>
          </div>
          
          <div class="summary-detail-row">
            <i data-lucide="calendar"></i>
            <div class="summary-detail-text">
              <span class="summary-detail-val">${formatDisplayDate(booking.date)}</span>
              <span class="summary-detail-sub">${booking.time}</span>
            </div>
          </div>
          
          <div class="summary-detail-row">
            <i data-lucide="user"></i>
            <div class="summary-detail-text">
              <span class="summary-detail-val">${booking.stylist}</span>
              <span class="summary-detail-sub">Senior Specialist</span>
            </div>
          </div>
          
          <div class="summary-detail-row" style="margin-bottom: 0;">
            <i data-lucide="map-pin"></i>
            <div class="summary-detail-text">
              <span class="summary-detail-val">Selvi's Beauty Parlour</span>
              <span class="summary-detail-sub">Sri Shiva nagar, Alasanatham Road, Hosur</span>
            </div>
          </div>
        </div>
        
        <!-- Points banner -->
        <div class="points-earned-banner">
          <span class="points-label"><i data-lucide="gift" style="width:14px; height:14px; display:inline; vertical-align:middle; margin-right:4px;"></i> Points Earned Today</span>
          <span class="points-value">+${booking.pointsEarned} pts</span>
        </div>
      </div>
      
      <button class="btn-primary" style="margin-bottom: 16px;" onclick="window.location.hash='#customer/dashboard'">
        <i data-lucide="calendar"></i> Add to Calendar & Exit
      </button>
    </div>
  `;
}

function renderAppointmentHistory(tab = 'upcoming') {
  const user = getCurrentUser();
  const bookings = getBookings().filter(b => b.customerName === user.name);
  
  const upcomingList = bookings.filter(b => b.status === 'Confirmed' || b.status === 'Pending');
  const historyList = bookings.filter(b => b.status === 'History' || b.status === 'Declined');
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Schedule details</span>
          <h1 class="header-title">My Appointments</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#customer/dashboard'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <!-- Tabs -->
      <div class="screen-tabs">
        <button class="tab-btn ${tab === 'upcoming' ? 'active' : ''}" onclick="window.location.hash='#customer/appointments?tab=upcoming'">Upcoming</button>
        <button class="tab-btn ${tab === 'history' ? 'active' : ''}" onclick="window.location.hash='#customer/appointments?tab=history'">History</button>
      </div>
      
      <div class="padded-container">
        ${tab === 'upcoming' ? 
          upcomingList.map(b => `
            <!-- Live Status Alert (If applicable) -->
            ${b.liveStatus && b.liveStatus.hasDelay ? `
              <div class="live-status-banner" style="margin-bottom: 12px;">
                <div class="live-pulse-container"><div class="live-pulse-dot"></div></div>
                <div class="live-status-text">
                  <div class="live-status-title">Live Stylist Delay Status</div>
                  Stylist finishing previous client. Delayed by 10 mins. New start time is 2:15 PM.
                </div>
              </div>
            ` : ''}
            
            <div class="app-card">
              <div class="card-title">
                <span>${b.serviceName}</span>
                <span class="badge ${b.status === 'Confirmed' ? 'badge-success' : 'badge-warning'}">${b.status}</span>
              </div>
              <div class="next-visit-time" style="margin-bottom: 12px;">
                <i data-lucide="calendar"></i> ${formatDisplayDate(b.date)} at ${b.time}
              </div>
              <div style="font-size: 11px; color: var(--light-text); margin-bottom: 14px;">
                Stylist: <strong>${b.stylist}</strong> &bull; Total: Rs. ${b.totalPaid}
              </div>
              
              <div style="display: flex; gap: 8px;">
                <button class="btn-secondary" style="flex: 1;" onclick="rescheduleBooking('${b.id}')"><i data-lucide="edit-3"></i> Reschedule</button>
                <button class="btn-secondary" style="flex: 0 0 40px; padding:0; border-color:var(--danger); color:var(--danger);" onclick="cancelBooking('${b.id}')"><i data-lucide="trash-2"></i></button>
              </div>
            </div>
          `).join('') || `<div style="text-align:center; padding: 40px 0; color: var(--light-text);">No upcoming visits</div>`
        : 
          historyList.map(b => `
            <div class="history-item-card">
              <div>
                <div style="font-weight: 600; font-size: 13px;">${b.serviceName}</div>
                <div style="font-size: 11px; color: var(--light-text);">${formatDisplayDate(b.date)} &bull; Stylist: ${b.stylist}</div>
              </div>
              <div style="text-align: right;">
                <div style="font-weight: 700; font-size: 12px; color: var(--secondary);">Rs. ${b.totalPaid}</div>
                <span class="badge ${b.status === 'History' ? 'badge-success' : 'badge-danger'}" style="margin-top: 4px;">
                  ${b.status === 'History' ? 'Completed' : 'Cancelled'}
                </span>
              </div>
            </div>
          `).join('') || `<div style="text-align:center; padding: 40px 0; color: var(--light-text);">No past history</div>`
        }
      </div>
      
      ${renderCustomerBottomNav('bookings')}
    </div>
  `;
}

function rescheduleBooking(bookingId) {
  const bookings = getBookings();
  const book = bookings.find(b => b.id === bookingId);
  if (book) {
    const services = getServices();
    const svc = services.find(s => s.name === book.serviceName) || services[0];
    startBooking(svc.id);
    // Delete original booking after starting new scheduling
    setBookings(bookings.filter(b => b.id !== bookingId));
  }
}

function cancelBooking(bookingId) {
  if (confirm("Are you sure you want to cancel this booking?")) {
    const bookings = getBookings();
    const book = bookings.find(b => b.id === bookingId);
    if (book) {
      book.status = "Declined"; // moves to history as cancelled
      setBookings(bookings);
      router();
    }
  }
}

function renderUserProfile() {
  const user = getCurrentUser();
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">My profile</span>
          <h1 class="header-title">User Profile</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#customer/dashboard'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <div class="profile-hero">
          <div class="profile-avatar-container">
            <img class="profile-avatar" src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80" alt="${user.name}">
            <div class="profile-avatar-edit"><i data-lucide="camera"></i></div>
          </div>
          <div class="profile-name">${user.name} <span class="badge badge-neutral">${user.badge}</span></div>
          <div class="profile-member-since">Member Since Oct 2021</div>
        </div>
        
        <!-- Stats row -->
        <div class="profile-stats-row">
          <div class="profile-stat-box">
            <div class="profile-stat-val">2</div>
            <div class="profile-stat-lbl">Upcoming</div>
          </div>
          <div class="profile-stat-box">
            <div class="profile-stat-val">14</div>
            <div class="profile-stat-lbl">Past Visits</div>
          </div>
          <div class="profile-stat-box highlight">
            <div class="profile-stat-val">${user.points}</div>
            <div class="profile-stat-lbl">Rewards Pts</div>
          </div>
        </div>
        
        <!-- Details -->
        <div class="time-grid-label">Personal Details</div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="phone"></i> <span>Phone Number</span></div>
          <div class="profile-detail-val">${user.phone}</div>
        </div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="mail"></i> <span>Email Address</span></div>
          <div class="profile-detail-val">${user.email}</div>
        </div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="gift"></i> <span>Birthday</span></div>
          <div class="profile-detail-val">${user.birthday}</div>
        </div>
        
        <div class="time-grid-label" style="margin-top: 20px;">Skin & Hair Diagnostics</div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="smile"></i> <span>Skin Diagnostics</span></div>
          <div class="profile-detail-val">${user.skinType}</div>
        </div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="scissors"></i> <span>Hair Profile</span></div>
          <div class="profile-detail-val">${user.hairType}</div>
        </div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="heart"></i> <span>Preferred Stylist</span></div>
          <div class="profile-detail-val">${user.preferredTech}</div>
        </div>
        
        <button class="btn-primary" style="background-color: var(--danger); border-color: var(--danger); box-shadow: 0 4px 12px rgba(255, 90, 95, 0.2); margin-top: 28px;" onclick="signOutUser()">
          <i data-lucide="log-out"></i> Log Out
        </button>
      </div>
      
      ${renderCustomerBottomNav('profile')}
    </div>
  `;
}

// Bottom navigation template helper for customers
function renderCustomerBottomNav(activeTab) {
  return `
    <nav class="bottom-nav">
      <a class="nav-item ${activeTab === 'home' ? 'active' : ''}" onclick="window.location.hash='#customer/dashboard'">
        <i data-lucide="home"></i> Home
      </a>
      <a class="nav-item ${activeTab === 'services' ? 'active' : ''}" onclick="window.location.hash='#customer/services'">
        <i data-lucide="scissors"></i> Services
      </a>
      <a class="nav-item-center" onclick="window.location.hash='#customer/services'">
        <i data-lucide="calendar"></i>
      </a>
      <a class="nav-item ${activeTab === 'bookings' ? 'active' : ''}" onclick="window.location.hash='#customer/appointments'">
        <i data-lucide="book-open"></i> Bookings
      </a>
      <a class="nav-item ${activeTab === 'profile' ? 'active' : ''}" onclick="window.location.hash='#customer/profile'">
        <i data-lucide="user"></i> Profile
      </a>
    </nav>
  `;
}

// ----------------------------------------------------
// OWNER / STAFF SCREENS RENDERERS
// ----------------------------------------------------

function renderOwnerDashboard() {
  const bookings = getBookings();
  const pendingList = bookings.filter(b => b.status === 'Pending');
  const confirmedList = bookings.filter(b => b.status === 'Confirmed');
  const historyList = bookings.filter(b => b.status === 'History');
  
  // Metrics calculation
  const totalRevenue = historyList.reduce((acc, curr) => acc + curr.totalPaid, 0) + 1240; // mock default base
  const capacityPct = Math.min(88 + (confirmedList.length * 2), 100); // dynamic slot load capacity
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Welcome back,</span>
          <h1 class="header-title">SELVI (Owner)</h1>
        </div>
        <div style="display: flex; gap: 8px;">
          <button class="icon-btn" onclick="signOutUser()" title="Log Out"><i data-lucide="log-out"></i></button>
          <button class="icon-btn badge-wrapper" onclick="window.location.hash='#owner/requests'">
            <i data-lucide="bell"></i>
            ${pendingList.length > 0 ? `<span class="btn-badge">${pendingList.length}</span>` : ''}
          </button>
        </div>
      </div>
      
      <div class="padded-container">
        <!-- Metrics grid -->
        <div class="owner-metrics-grid">
          <div class="metric-card">
            <div class="metric-header">
              <span>Monthly Revenue</span>
              <div class="metric-icon revenue"><i data-lucide="dollar-sign"></i></div>
            </div>
            <div class="metric-val">Rs. ${totalRevenue.toLocaleString()}</div>
            <div class="metric-desc" style="color: var(--success);">+12% vs last month</div>
          </div>
          
          <div class="metric-card">
            <div class="metric-header">
              <span>Booked Slots</span>
              <div class="metric-icon slots"><i data-lucide="calendar"></i></div>
            </div>
            <div class="metric-val">${capacityPct}%</div>
            <div class="metric-desc" style="color: var(--primary);">${confirmedList.length + historyList.length} active sessions today</div>
          </div>
        </div>
        
        <!-- Live happening now ticker card -->
        <div class="banner-booking-card" style="background: linear-gradient(135deg, #0A0A0B 0%, #1E1F22 100%); margin-bottom: 20px;" onclick="window.location.hash='#owner/happening-now'">
          <div style="display:flex; justify-content:space-between; align-items:center;">
            <span class="badge badge-neutral" style="background:var(--primary); color:#FFFFFF; margin-bottom:10px;">Happening Now</span>
            <div class="live-pulse-dot"></div>
          </div>
          <div style="font-size: 16px; font-weight:700; margin-bottom:4px;">${timerState.activeClient}</div>
          <div style="font-size: 11px; opacity:0.8; margin-bottom:10px;">${timerState.activeService} &bull; Stylist: Selvi</div>
          <div style="display:flex; align-items:center; gap:8px;">
            <div id="owner-dash-timer" style="font-family: monospace; font-size:18px; font-weight:700;">12:45</div>
            <span style="font-size:10px; opacity:0.6;">minutes remaining</span>
          </div>
        </div>
        
        <!-- Pending requests shortcut widget -->
        <div class="section-header">
          <div class="section-title">Pending Requests (${pendingList.length})</div>
          <span class="section-link" onclick="window.location.hash='#owner/requests'">View all</span>
        </div>
        
        <div class="pending-requests-shortcut" style="margin-bottom: 20px;">
          ${pendingList.slice(0, 2).map(r => `
            <div class="request-card">
              <div class="request-header">
                <span class="request-client-name">${r.customerName}</span>
                <span style="font-size:11px; font-weight:700; color:var(--primary);">Rs. ${r.price}</span>
              </div>
              <div class="request-service-info">
                <span>${r.serviceName}</span>
                <span style="color:var(--light-text); font-size:10px;">${formatDisplayDate(r.date)} &bull; ${r.time}</span>
              </div>
              <div class="request-action-row">
                <button class="btn-action decline" onclick="declineRequest('${r.id}')">Decline</button>
                <button class="btn-action approve" onclick="approveRequest('${r.id}')">Approve</button>
              </div>
            </div>
          `).join('') || `<div style="text-align:center; padding:20px; border:1px dashed var(--border-color); border-radius:12px; color:var(--light-text); font-size:12px;">No pending requests</div>`}
        </div>
        
        <!-- Weekly schedule layout widget -->
        <div class="schedule-widget">
          <div class="schedule-widget-header">
            <span class="section-title" style="font-size: 13px;">Weekly Schedule</span>
            <span class="section-link" onclick="window.location.hash='#owner/schedule'">View full</span>
          </div>
          <div class="weekly-schedule-row">
            <div class="schedule-day-col"><span class="schedule-day-lbl">Mon</span><span class="schedule-day-num">13</span></div>
            <div class="schedule-day-col active"><span class="schedule-day-lbl">Tue</span><span class="schedule-day-num">14</span></div>
            <div class="schedule-day-col"><span class="schedule-day-lbl">Wed</span><span class="schedule-day-num">15</span></div>
            <div class="schedule-day-col"><span class="schedule-day-lbl">Thu</span><span class="schedule-day-num">16</span></div>
            <div class="schedule-day-col"><span class="schedule-day-lbl">Fri</span><span class="schedule-day-num">17</span></div>
            <div class="schedule-day-col"><span class="schedule-day-lbl">Sat</span><span class="schedule-day-num">18</span></div>
            <div class="schedule-day-col"><span class="schedule-day-lbl">Sun</span><span class="schedule-day-num">19</span></div>
          </div>
        </div>
      </div>
      
      ${renderOwnerBottomNav('dashboard')}
    </div>
  `;
}

function approveRequest(bookingId) {
  const bookings = getBookings();
  const book = bookings.find(b => b.id === bookingId);
  if (book) {
    book.status = "Confirmed";
    setBookings(bookings);
    alert(`Appointment for ${book.customerName} approved!`);
    router();
  }
}

function declineRequest(bookingId) {
  const bookings = getBookings();
  const book = bookings.find(b => b.id === bookingId);
  if (book) {
    book.status = "Declined";
    setBookings(bookings);
    alert(`Appointment for ${book.customerName} declined.`);
    router();
  }
}

function renderHappeningNow() {
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Active Session</span>
          <h1 class="header-title">Happening Now</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#owner/dashboard'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container" style="display:flex; flex-direction:column; justify-content:space-between;">
        <div class="timer-container">
          <div class="timer-circle-wrapper">
            <svg class="timer-svg" viewBox="0 0 100 100">
              <circle class="timer-track" cx="50" cy="50" r="45"></circle>
              <circle class="timer-progress" id="timer-svg-circle" cx="50" cy="50" r="45" stroke-dasharray="283" stroke-dashoffset="0"></circle>
            </svg>
            <div class="timer-display">
              <span class="timer-number" id="timer-countdown-string">12:45</span>
              <span class="timer-label">Remaining</span>
            </div>
          </div>
          
          <div style="text-align:center;">
            <h2 style="font-size:16px; font-weight:700; color:var(--secondary);">${timerState.activeClient}</h2>
            <p style="font-size:12px; color:var(--light-text); margin-top:2px;">Service: ${timerState.activeService} &bull; Stylist: Selvi</p>
          </div>
        </div>
        
        <div>
          <div class="timer-action-buttons">
            <button class="btn-timer-tweak" onclick="addTimerTime(-60)">-1 Min</button>
            <button class="btn-timer-tweak" onclick="addTimerTime(300)">+5 Mins</button>
            <button class="btn-timer-tweak" onclick="addTimerTime(600)">+10 Mins</button>
          </div>
          
          <button class="btn-primary" style="background-color: var(--success); box-shadow: 0 4px 12px rgba(46,196,182,0.2); margin-bottom:16px;" onclick="finishSessionEarly()">
            <i data-lucide="check-circle"></i> Finish Session Early
          </button>
        </div>
      </div>
      
      ${renderOwnerBottomNav('dashboard')}
    </div>
  `;
}

function setupTimerSVG() {
  const circle = document.getElementById('timer-svg-circle');
  if (!circle) return;
  
  // Calculate percentage remaining
  const pct = timerState.currentSeconds / timerState.totalSeconds;
  const offset = 283 - (pct * 283);
  circle.setAttribute('stroke-dashoffset', offset);
}

function addTimerTime(seconds) {
  timerState.currentSeconds = Math.max(0, timerState.currentSeconds + seconds);
  // Also adjust total seconds if it exceeds original
  if (timerState.currentSeconds > timerState.totalSeconds) {
    timerState.totalSeconds = timerState.currentSeconds;
  }
  
  updateTimerUI();
}

function finishSessionEarly() {
  timerState.currentSeconds = 0;
  updateTimerUI();
  alert("Session completed successfully! The revenue has been added to your dashboard statistics.");
  
  // Mark Monica Bellucci's booking as completed history
  const bookings = getBookings();
  const book = bookings.find(b => b.customerName === "Monica Bellucci" && b.status === "Confirmed");
  if (book) {
    book.status = "History";
    setBookings(bookings);
  }
  
  window.location.hash = '#owner/dashboard';
}

function updateTimerUI() {
  const label = document.getElementById('timer-countdown-string');
  const dashLabel = document.getElementById('owner-dash-timer');
  
  const minutes = Math.floor(timerState.currentSeconds / 60);
  const seconds = timerState.currentSeconds % 60;
  const timeString = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
  
  if (label) label.innerText = timeString;
  if (dashLabel) dashLabel.innerText = timeString;
  
  setupTimerSVG();
}

// Background live countdown timer trigger
function startLiveTimer() {
  if (timerState.intervalId) clearInterval(timerState.intervalId);
  
  timerState.intervalId = setInterval(() => {
    if (timerState.currentSeconds > 0) {
      timerState.currentSeconds--;
      updateTimerUI();
    } else {
      // Loop or stop
      timerState.currentSeconds = timerState.totalSeconds; // Reset loop for demo
    }
  }, 1000);
}

function renderAppointmentRequests(tab = 'pending') {
  const bookings = getBookings();
  const pendingList = bookings.filter(b => b.status === 'Pending');
  const confirmedList = bookings.filter(b => b.status === 'Confirmed');
  const historyList = bookings.filter(b => b.status === 'History' || b.status === 'Declined');
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Client submissions</span>
          <h1 class="header-title">Appointment Requests</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#owner/dashboard'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <!-- Tabs -->
      <div class="screen-tabs">
        <button class="tab-btn ${tab === 'pending' ? 'active' : ''}" onclick="window.location.hash='#owner/requests?tab=pending'">Pending (${pendingList.length})</button>
        <button class="tab-btn ${tab === 'confirmed' ? 'active' : ''}" onclick="window.location.hash='#owner/requests?tab=confirmed'">Confirmed</button>
        <button class="tab-btn ${tab === 'history' ? 'active' : ''}" onclick="window.location.hash='#owner/requests?tab=history'">History</button>
      </div>
      
      <div class="padded-container">
        ${tab === 'pending' ? 
          pendingList.map(r => `
            <div class="request-card">
              <div class="request-header">
                <span class="request-client-name" style="color:var(--secondary); font-size:14px;">${r.customerName}</span>
                <span style="font-weight:700; color:var(--primary);">Rs. ${r.price}</span>
              </div>
              <div class="request-service-info">
                <strong>${r.serviceName}</strong>
                <span style="color:var(--light-text);">${formatDisplayDate(r.date)} &bull; ${r.time} &bull; Stylist: ${r.stylist}</span>
              </div>
              <div class="request-action-row">
                <button class="btn-action decline" onclick="declineRequest('${r.id}')">Decline</button>
                <button class="btn-action approve" onclick="approveRequest('${r.id}')">Approve</button>
              </div>
            </div>
          `).join('') || `<div style="text-align:center; padding:40px 0; color:var(--light-text);">No pending requests</div>`
        : tab === 'confirmed' ?
          confirmedList.map(r => `
            <div class="request-card" style="border-left: 4px solid var(--success);">
              <div class="request-header">
                <span class="request-client-name">${r.customerName}</span>
                <span style="font-weight:700; color:var(--secondary);">Rs. ${r.price}</span>
              </div>
              <div class="request-service-info">
                <strong>${r.serviceName}</strong>
                <span style="color:var(--light-text);">${formatDisplayDate(r.date)} &bull; ${r.time}</span>
              </div>
              <div style="display:flex; justify-content:space-between; align-items:center; font-size:11px; margin-top:10px; border-top: 1px solid var(--border-color); padding-top:8px;">
                <span style="color:var(--success); font-weight:600;"><i data-lucide="check" style="width:12px; height:12px; display:inline-block; vertical-align:middle;"></i> Confirmed</span>
                <span style="color:var(--light-text);">Paid via Credit Card</span>
              </div>
            </div>
          `).join('') || `<div style="text-align:center; padding:40px 0; color:var(--light-text);">No confirmed bookings</div>`
        :
          historyList.map(r => `
            <div class="request-card">
              <div class="request-header">
                <span class="request-client-name">${r.customerName}</span>
                <span style="font-weight:700; color:var(--light-text);">Rs. ${r.price}</span>
              </div>
              <div class="request-service-info">
                <strong>${r.serviceName}</strong>
                <span style="color:var(--light-text);">${formatDisplayDate(r.date)} &bull; ${r.time}</span>
              </div>
              <span class="badge ${r.status === 'History' ? 'badge-success' : 'badge-danger'}" style="margin-top:4px;">
                ${r.status === 'History' ? 'Completed' : 'Cancelled/Declined'}
              </span>
            </div>
          `).join('') || `<div style="text-align:center; padding:40px 0; color:var(--light-text);">No request history</div>`
        }
      </div>
      
      ${renderOwnerBottomNav('requests')}
    </div>
  `;
}

function renderMasterSchedule() {
  const bookings = getBookings().filter(b => b.status === 'Confirmed' || b.status === 'History');
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Daily planner</span>
          <h1 class="header-title">Master Schedule</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#owner/dashboard'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <!-- Mini Date selector -->
        <div class="weekly-schedule-row" style="margin-bottom: 20px;">
          <div class="schedule-day-col"><span class="schedule-day-lbl">Mon</span><span class="schedule-day-num">13</span></div>
          <div class="schedule-day-col active"><span class="schedule-day-lbl">Tue</span><span class="schedule-day-num">14</span></div>
          <div class="schedule-day-col"><span class="schedule-day-lbl">Wed</span><span class="schedule-day-num">15</span></div>
          <div class="schedule-day-col"><span class="schedule-day-lbl">Thu</span><span class="schedule-day-num">16</span></div>
          <div class="schedule-day-col"><span class="schedule-day-lbl">Fri</span><span class="schedule-day-num">17</span></div>
          <div class="schedule-day-col"><span class="schedule-day-lbl">Sat</span><span class="schedule-day-num">18</span></div>
        </div>
        
        <div class="schedule-list">
          ${bookings.map(b => `
            <div class="schedule-item">
              <div class="schedule-item-time">
                <span>${b.time.split(' ')[0]}</span>
                <span>${b.time.split(' ')[1]}</span>
              </div>
              <div class="schedule-item-body">
                <div class="schedule-item-details">
                  <span class="schedule-item-client" onclick="window.location.hash='#owner/profile?id=cust-${b.customerName.toLowerCase().split(' ')[0]}'">${b.customerName}</span>
                  <span class="schedule-item-svc">${b.serviceName} &bull; ${b.duration} mins</span>
                </div>
                <button class="schedule-check-btn ${b.status === 'History' ? 'completed' : ''}" onclick="toggleBookingCompleted('${b.id}')">
                  <i data-lucide="check"></i>
                </button>
              </div>
            </div>
          `).join('') || `<div style="text-align:center; padding:40px 0; color:var(--light-text);">No bookings scheduled for today</div>`}
        </div>
      </div>
      
      ${renderOwnerBottomNav('schedule')}
    </div>
  `;
}

function toggleBookingCompleted(bookingId) {
  const bookings = getBookings();
  const book = bookings.find(b => b.id === bookingId);
  if (book) {
    if (book.status === 'Confirmed') {
      book.status = 'History';
      alert(`Booking marked as completed!`);
    } else {
      book.status = 'Confirmed';
    }
    setBookings(bookings);
    router();
  }
}

function renderManageServices() {
  const services = getServices();
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Menu configuration</span>
          <h1 class="header-title">Manage Services</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#owner/dashboard'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <!-- Service Stats banner -->
        <div class="profile-stats-row" style="margin-bottom: 20px;">
          <div class="profile-stat-box">
            <div class="profile-stat-val">${services.length}</div>
            <div class="profile-stat-lbl">Total Treatments</div>
          </div>
          <div class="profile-stat-box">
            <div class="profile-stat-val">${services.filter(s => s.active).length}</div>
            <div class="profile-stat-lbl">Active Online</div>
          </div>
        </div>
        
        <div class="treatment-list">
          ${services.map(s => `
            <div class="treatment-item">
              <div class="treatment-info">
                <span class="treatment-name">${s.name}</span>
                <div class="treatment-meta-row">
                  <span>${s.duration} mins</span>
                  <span>&bull;</span>
                  <span>Rs. <input type="number" class="treatment-price-edit" value="${s.price}" onchange="updateServicePrice('${s.id}', this.value)"></span>
                </div>
              </div>
              
              <label class="toggle-switch-wrapper">
                <input type="checkbox" ${s.active ? 'checked' : ''} onchange="toggleServiceActiveState('${s.id}', this.checked)">
                <span class="toggle-slider"></span>
              </label>
            </div>
          `).join('')}
        </div>
      </div>
      
      ${renderOwnerBottomNav('services')}
    </div>
  `;
}

function toggleServiceActiveState(serviceId, active) {
  const services = getServices();
  const svc = services.find(s => s.id === serviceId);
  if (svc) {
    svc.active = active;
    setServices(services);
  }
}

function updateServicePrice(serviceId, price) {
  const services = getServices();
  const svc = services.find(s => s.id === serviceId);
  if (svc) {
    svc.price = parseInt(price) || svc.price;
    setServices(services);
  }
}

function renderCustomerDirectory() {
  const customers = getCustomers();
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">CRM directory</span>
          <h1 class="header-title">Customer Directory</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#owner/dashboard'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <!-- Search bar -->
        <div class="search-bar-container">
          <i data-lucide="search"></i>
          <input type="text" id="crm-search-input" class="search-input" placeholder="Search clients by name..." oninput="filterCRMList()">
        </div>
        
        <!-- List -->
        <div class="client-directory-list" id="crm-clients-list">
          ${customers.map(c => `
            <div class="directory-item" onclick="window.location.hash='#owner/profile?id=${c.id}'">
              <div class="directory-item-left">
                <img class="directory-avatar" src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=80&q=80">
                <div class="directory-info">
                  <span class="directory-name">${c.name}</span>
                  <span class="directory-status badge ${
                    c.badge === 'Punctual' ? 'badge-success' : 
                    c.badge === 'Occasional' ? 'badge-warning' : 'badge-danger'
                  }">${c.badge}</span>
                </div>
              </div>
              <i data-lucide="chevron-right" style="color:var(--light-text); width:16px;"></i>
            </div>
          `).join('')}
        </div>
      </div>
      
      ${renderOwnerBottomNav('directory')}
    </div>
  `;
}

function filterCRMList() {
  const query = document.getElementById('crm-search-input').value.toLowerCase();
  const items = document.querySelectorAll('#crm-clients-list .directory-item');
  items.forEach(item => {
    const name = item.querySelector('.directory-name').innerText.toLowerCase();
    if (name.includes(query)) {
      item.style.display = 'flex';
    } else {
      item.style.display = 'none';
    }
  });
}

function renderOwnerCustomerProfile(customerId) {
  const customer = getCustomers().find(c => c.id === customerId) || getCustomers()[0];
  
  return `
    <div class="animated-screen">
      <div class="screen-header">
        <div class="header-title-container">
          <span class="header-subtitle">Client records</span>
          <h1 class="header-title">Customer Profile</h1>
        </div>
        <button class="icon-btn" onclick="window.location.hash='#owner/directory'"><i data-lucide="chevron-left"></i></button>
      </div>
      
      <div class="padded-container">
        <div class="profile-hero">
          <img class="profile-avatar" src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80" alt="${customer.name}">
          <div class="profile-name" style="margin-top:10px;">${customer.name}</div>
          <span class="badge ${customer.badge === 'Punctual' ? 'badge-success' : customer.badge === 'Occasional' ? 'badge-warning' : 'badge-danger'}" style="margin-top:6px;">${customer.badge} Badge</span>
        </div>
        
        <!-- Stats summary row -->
        <div class="profile-stats-row">
          <div class="profile-stat-box">
            <div class="profile-stat-val">${customer.reliability}%</div>
            <div class="profile-stat-lbl">Reliability</div>
          </div>
          <div class="profile-stat-box">
            <div class="profile-stat-val">${customer.hospitalityRating}%</div>
            <div class="profile-stat-lbl">Hosp. Rating</div>
          </div>
          <div class="profile-stat-box">
            <div class="profile-stat-val">${customer.cancellations}</div>
            <div class="profile-stat-lbl">Cancellations</div>
          </div>
        </div>
        
        <!-- Private note section -->
        <div class="owner-notes-card">
          <div class="owner-notes-header">
            <span>OWNER'S PRIVATE NOTE</span>
            <i data-lucide="edit-2" style="width:12px; height:12px;"></i>
          </div>
          <textarea class="owner-notes-textarea" id="owner-client-private-note" onblur="saveOwnerPrivateNote('${customer.id}', this.value)">${customer.privateNote}</textarea>
          <div style="font-size:9px; color:#B27B00; text-align:right; margin-top:4px;">Auto-saves when you click out</div>
        </div>
        
        <!-- Details -->
        <div class="time-grid-label">Contact Details</div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="phone"></i> <span>Phone Number</span></div>
          <div class="profile-detail-val">${customer.phone}</div>
        </div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="mail"></i> <span>Email Address</span></div>
          <div class="profile-detail-val">${customer.email}</div>
        </div>
        
        <div class="time-grid-label" style="margin-top:20px;">Personal Notes</div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="smile"></i> <span>Skin Diagnostics</span></div>
          <div class="profile-detail-val">${customer.skinType}</div>
        </div>
        <div class="profile-detail-item">
          <div class="profile-detail-left"><i data-lucide="scissors"></i> <span>Hair Profile</span></div>
          <div class="profile-detail-val">${customer.hairType}</div>
        </div>
      </div>
      
      ${renderOwnerBottomNav('directory')}
    </div>
  `;
}

function saveOwnerPrivateNote(customerId, note) {
  const customers = getCustomers();
  const c = customers.find(c => c.id === customerId);
  if (c) {
    c.privateNote = note;
    setCustomers(customers);
  }
}

// Bottom navigation template helper for owners
function renderOwnerBottomNav(activeTab) {
  return `
    <nav class="bottom-nav">
      <a class="nav-item ${activeTab === 'dashboard' ? 'active' : ''}" onclick="window.location.hash='#owner/dashboard'">
        <i data-lucide="home"></i> Home
      </a>
      <a class="nav-item ${activeTab === 'services' ? 'active' : ''}" onclick="window.location.hash='#owner/services'">
        <i data-lucide="scissors"></i> Services
      </a>
      <a class="nav-item-center" style="background-color: var(--secondary);" onclick="window.location.hash='#owner/happening-now'">
        <i data-lucide="play"></i>
      </a>
      <a class="nav-item ${activeTab === 'schedule' ? 'active' : ''}" onclick="window.location.hash='#owner/schedule'">
        <i data-lucide="calendar"></i> Schedule
      </a>
      <a class="nav-item ${activeTab === 'directory' ? 'active' : ''}" onclick="window.location.hash='#owner/directory'">
        <i data-lucide="users"></i> CRM
      </a>
    </nav>
  `;
}

// ----------------------------------------------------
// SYSTEM GENERIC HELPERS
// ----------------------------------------------------

// Formats calendar date (YYYY-MM-DD) to friendly format (e.g. "Monday, Oct 13th")
function formatDisplayDate(dateStr) {
  const date = new Date(dateStr);
  const weekday = date.toLocaleDateString('en-US', { weekday: 'long' });
  const month = date.toLocaleDateString('en-US', { month: 'short' });
  const day = date.getDate();
  
  // Ordinal suffix
  let suffix = 'th';
  if (day === 1 || day === 21 || day === 31) suffix = 'st';
  else if (day === 2 || day === 22) suffix = 'nd';
  else if (day === 3 || day === 23) suffix = 'rd';
  
  return `${weekday}, ${month} ${day}${suffix}`;
}

function signOutUser() {
  if (isFirebaseConfigured() && auth) {
    signOut(auth).then(() => {
      localStorage.removeItem("selvi_current_user");
      window.location.hash = "#customer/get-started";
    }).catch(error => {
      console.error("Firebase Signout Error:", error);
    });
  } else {
    localStorage.removeItem("selvi_current_user");
    window.location.hash = "#customer/get-started";
  }
}

// Bind ES Module scoped functions to global window object
// so inline HTML templates can access them cleanly.
window.switchPerspective = switchPerspective;
window.startBooking = startBooking;
window.filterServices = filterServices;
window.filterByCategory = filterByCategory;
window.selectOccasion = selectOccasion;
window.selectTimeSlot = selectTimeSlot;
window.adjustCalendarMonth = adjustCalendarMonth;
window.selectCalendarDate = selectCalendarDate;
window.applyPointsReward = applyPointsReward;
window.toggleDiscountState = toggleDiscountState;
window.selectPaymentOption = selectPaymentOption;
window.executeBookingOrder = executeBookingOrder;
window.rescheduleBooking = rescheduleBooking;
window.cancelBooking = cancelBooking;
window.approveRequest = approveRequest;
window.declineRequest = declineRequest;
window.addTimerTime = addTimerTime;
window.finishSessionEarly = finishSessionEarly;
window.toggleBookingCompleted = toggleBookingCompleted;
window.toggleServiceActiveState = toggleServiceActiveState;
window.updateServicePrice = updateServicePrice;
window.filterCRMList = filterCRMList;
window.saveOwnerPrivateNote = saveOwnerPrivateNote;
window.executeLogin = executeLogin;
window.executeSignUp = executeSignUp;
window.selectLoginRole = selectLoginRole;
window.selectSignupRole = selectSignupRole;
window.signOutUser = signOutUser;
