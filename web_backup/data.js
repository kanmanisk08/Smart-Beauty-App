// Initial Mock Database for Selvi's Beauty Parlour
const DEFAULT_SERVICES = [
  {
    id: "svc-1",
    name: "Women's Cut & Style",
    price: 300,
    duration: 45,
    category: "Haircuts",
    description: "Includes custom consultation, shampoo, conditioning, blow dry & styling.",
    active: true,
    image: "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=150&q=80"
  },
  {
    id: "svc-2",
    name: "Gel Manicure",
    price: 400,
    duration: 45,
    category: "Nails",
    description: "Long-lasting gel polish with professional cut & file. Includes scalp & hand massage prep.",
    active: true,
    image: "https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=150&q=80"
  },
  {
    id: "svc-3",
    name: "Full Balayage & Styling",
    price: 1500,
    duration: 90,
    category: "Hair Coloring",
    description: "Expert hand-painted coloring technique for a soft, natural, sun-kissed look.",
    active: true,
    image: "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=150&q=80"
  },
  {
    id: "svc-4",
    name: "Root Touch-up",
    price: 600,
    duration: 45,
    category: "Hair Coloring",
    description: "Perfect coverage for new hair growth to match your current shade.",
    active: true,
    image: "https://images.unsplash.com/photo-1605497746444-12d733b04bd5?auto=format&fit=crop&w=150&q=80"
  },
  {
    id: "svc-5",
    name: "Hydrating Facial",
    price: 700,
    duration: 60,
    category: "Skincare",
    description: "Deep nourishing hydrating treatment for a glowing, fresh, and radiant skin complexion.",
    active: true,
    image: "https://images.unsplash.com/photo-1590156546746-c58af9983941?auto=format&fit=crop&w=150&q=80"
  },
  {
    id: "svc-6",
    name: "Express Mani",
    price: 300,
    duration: 30,
    category: "Nails",
    description: "Quick clean, shaping, cuticle care, and standard polish of your choice.",
    active: true,
    image: "https://images.unsplash.com/photo-1519014816548-bf5fe059798b?auto=format&fit=crop&w=150&q=80"
  }
];

const DEFAULT_CUSTOMERS = [
  {
    id: "cust-monica",
    name: "Monica Bellucci",
    badge: "Punctual",
    memberSince: "Oct 2021",
    phone: "+91 1234567890",
    email: "example@gmail.com",
    birthday: "Jan 14",
    skinType: "Sensitive, Dry",
    hairType: "Curly, 3B",
    preferredTech: "Selvi",
    points: 850,
    reliability: 90,
    hospitalityRating: 98,
    cancellations: 1,
    privateNote: "Monica prefers cooler tones for her Balayage. Very chatty about her travel plans, likes the head massage to be firm."
  },
  {
    id: "cust-kannani",
    name: "Kannani",
    badge: "Punctual",
    memberSince: "Jan 2023",
    phone: "+91 9876543210",
    email: "kannani@example.com",
    birthday: "Mar 22",
    skinType: "Normal",
    hairType: "Straight, 1A",
    preferredTech: "Selvi",
    points: 340,
    reliability: 95,
    hospitalityRating: 99,
    cancellations: 0,
    privateNote: "Likes quiet visits. Prefers green tea. Frequent gel nails customer."
  },
  {
    id: "cust-kanishka",
    name: "Kanishka",
    badge: "Occasional",
    memberSince: "Feb 2024",
    phone: "+91 9900887766",
    email: "kanishka@example.com",
    birthday: "Jul 05",
    skinType: "Oily, Acne-prone",
    hairType: "Wavy, 2A",
    preferredTech: "Selvi",
    points: 150,
    reliability: 80,
    hospitalityRating: 92,
    cancellations: 2,
    privateNote: "Often running 5-10 mins late. Loves experimenting with bold nail art."
  },
  {
    id: "cust-harini",
    name: "Harini",
    badge: "Punctual",
    memberSince: "Aug 2022",
    phone: "+91 8877665544",
    email: "harini@example.com",
    birthday: "Nov 30",
    skinType: "Combination",
    hairType: "Coily, 4A",
    preferredTech: "Selvi",
    points: 620,
    reliability: 100,
    hospitalityRating: 100,
    cancellations: 0,
    privateNote: "Regular customer for manicure and haircuts. Very friendly and leaves great reviews."
  },
  {
    id: "cust-sarah",
    name: "Sarah Jenkins",
    badge: "Needs Attention",
    memberSince: "Sep 2023",
    phone: "+91 7766554433",
    email: "sarah@example.com",
    birthday: "May 18",
    skinType: "Sensitive",
    hairType: "Wavy, 2B",
    preferredTech: "Selvi",
    points: 90,
    reliability: 70,
    hospitalityRating: 85,
    cancellations: 3,
    privateNote: "Needs attention. Reschedules frequently. High cancellation rate."
  }
];

const DEFAULT_BOOKINGS = [
  {
    id: "bk-1",
    customerName: "Monica Bellucci",
    customerPhone: "+91 1234567890",
    customerEmail: "example@gmail.com",
    serviceName: "Full Balayage & Styling",
    price: 400, // Custom discounted price shown in mockup
    duration: 90,
    date: "2026-07-13", // A Monday
    time: "11:00 AM",
    stylist: "Selvi",
    status: "Confirmed",
    loyaltyDiscount: 50,
    tax: 28.50,
    totalPaid: 378.50,
    pointsApplied: 50,
    pointsEarned: 50,
    liveStatus: {
      hasDelay: true,
      delayMinutes: 10,
      adjustedTime: "2:15 PM",
      notes: "Your stylist is finishing up a previous service."
    }
  },
  {
    id: "bk-2",
    customerName: "Kannani",
    customerPhone: "+91 9876543210",
    customerEmail: "kannani@example.com",
    serviceName: "Gel Manicure",
    price: 400,
    duration: 45,
    date: "2026-07-13",
    time: "12:30 PM",
    stylist: "Selvi",
    status: "Pending",
    loyaltyDiscount: 0,
    tax: 30.00,
    totalPaid: 430.00,
    pointsApplied: 0,
    pointsEarned: 40
  },
  {
    id: "bk-3",
    customerName: "Anushaa",
    customerPhone: "+91 9999888877",
    customerEmail: "anushaa@example.com",
    serviceName: "Women's Cut & Style",
    price: 300,
    duration: 45,
    date: "2026-07-13",
    time: "03:00 PM",
    stylist: "Selvi",
    status: "Pending",
    loyaltyDiscount: 0,
    tax: 22.50,
    totalPaid: 322.50,
    pointsApplied: 0,
    pointsEarned: 30
  },
  {
    id: "bk-4",
    customerName: "Menaka",
    customerPhone: "+91 8888777766",
    customerEmail: "menaka@example.com",
    serviceName: "Hydrating Facial",
    price: 700,
    duration: 60,
    date: "2026-07-13",
    time: "04:30 PM",
    stylist: "Selvi",
    status: "Pending",
    loyaltyDiscount: 0,
    tax: 52.50,
    totalPaid: 752.50,
    pointsApplied: 0,
    pointsEarned: 70
  },
  // History appointments for Monica Bellucci
  {
    id: "bk-hist-1",
    customerName: "Monica Bellucci",
    customerPhone: "+91 1234567890",
    customerEmail: "example@gmail.com",
    serviceName: "Gel Manicure",
    price: 400,
    duration: 45,
    date: "2026-07-03", // 1 week ago
    time: "10:00 AM",
    stylist: "Selvi",
    status: "History",
    totalPaid: 428.50,
    pointsApplied: 0,
    pointsEarned: 40
  },
  {
    id: "bk-hist-2",
    customerName: "Monica Bellucci",
    customerPhone: "+91 1234567890",
    customerEmail: "example@gmail.com",
    serviceName: "Full Balayage & Styling",
    price: 1500,
    duration: 90,
    date: "2026-06-10", // 1 month ago
    time: "02:00 PM",
    stylist: "Selvi",
    status: "History",
    totalPaid: 1605.00,
    pointsApplied: 0,
    pointsEarned: 150
  },
  {
    id: "bk-hist-3",
    customerName: "Monica Bellucci",
    customerPhone: "+91 1234567890",
    customerEmail: "example@gmail.com",
    serviceName: "Hydrating Facial",
    price: 700,
    duration: 60,
    date: "2026-05-10", // 2 months ago
    time: "11:00 AM",
    stylist: "Selvi",
    status: "History",
    totalPaid: 749.00,
    pointsApplied: 0,
    pointsEarned: 70
  },
  {
    id: "bk-hist-4",
    customerName: "Monica Bellucci",
    customerPhone: "+91 1234567890",
    customerEmail: "example@gmail.com",
    serviceName: "Express Mani",
    price: 300,
    duration: 30,
    date: "2026-04-10", // 3 months ago
    time: "04:00 PM",
    stylist: "Selvi",
    status: "History",
    totalPaid: 321.00,
    pointsApplied: 0,
    pointsEarned: 30
  }
];

// Helper to initialize database in localStorage
function initDatabase() {
  if (!localStorage.getItem("selvi_services")) {
    localStorage.setItem("selvi_services", JSON.stringify(DEFAULT_SERVICES));
  }
  if (!localStorage.getItem("selvi_customers")) {
    localStorage.setItem("selvi_customers", JSON.stringify(DEFAULT_CUSTOMERS));
  }
  if (!localStorage.getItem("selvi_bookings")) {
    localStorage.setItem("selvi_bookings", JSON.stringify(DEFAULT_BOOKINGS));
  }
  
  // Set active customer to Monica Bellucci for mock flows
  if (!localStorage.getItem("selvi_current_user")) {
    localStorage.setItem("selvi_current_user", JSON.stringify(DEFAULT_CUSTOMERS[0]));
  }
}

// Retrieve data functions
function getServices() {
  return JSON.parse(localStorage.getItem("selvi_services")) || DEFAULT_SERVICES;
}

function setServices(services) {
  localStorage.setItem("selvi_services", JSON.stringify(services));
}

function getCustomers() {
  return JSON.parse(localStorage.getItem("selvi_customers")) || DEFAULT_CUSTOMERS;
}

function setCustomers(customers) {
  localStorage.setItem("selvi_customers", JSON.stringify(customers));
}

function getBookings() {
  return JSON.parse(localStorage.getItem("selvi_bookings")) || DEFAULT_BOOKINGS;
}

function setBookings(bookings) {
  localStorage.setItem("selvi_bookings", JSON.stringify(bookings));
}

function getCurrentUser() {
  return JSON.parse(localStorage.getItem("selvi_current_user")) || DEFAULT_CUSTOMERS[0];
}

function setCurrentUser(user) {
  localStorage.setItem("selvi_current_user", JSON.stringify(user));
  // Sync in customer list as well
  const customers = getCustomers();
  const index = customers.findIndex(c => c.id === user.id);
  if (index !== -1) {
    customers[index] = user;
    setCustomers(customers);
  }
}

// Initialize database when script loads
initDatabase();
