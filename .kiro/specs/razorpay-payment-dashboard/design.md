# Design Document: Razorpay Payment Dashboard

## Overview

The Razorpay Payment Dashboard is a React-based single-page application (SPA) that provides a modern, responsive interface for managing Razorpay payment operations. The application follows a component-based architecture with clear separation of concerns between UI components, API integration, and state management.

### Technology Stack

- **Frontend Framework**: React 18 with functional components and hooks
- **Build Tool**: Vite for fast development and optimized production builds
- **Styling**: TailwindCSS v3 for utility-first responsive design
- **HTTP Client**: Axios for API communication with interceptors
- **Routing**: React Router v6 for client-side navigation
- **Code Quality**: ESLint and Prettier for consistent code standards

### Key Design Principles

1. **Component Reusability**: Shared components (ResultBox, LoadingSpinner, Navbar) used across features
2. **Declarative UI**: React's declarative approach for predictable state-to-UI mapping
3. **Responsive-First**: Mobile-first design using TailwindCSS breakpoints
4. **Accessibility**: WCAG 2.1 AA compliance with semantic HTML and ARIA attributes
5. **Error Resilience**: Comprehensive error handling at API and component levels

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Browser (Client)                      │
│  ┌───────────────────────────────────────────────────┐  │
│  │           React Application (SPA)                  │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  Presentation Layer                          │  │  │
│  │  │  - Navbar                                    │  │  │
│  │  │  - HomePage (Order Creation)                 │  │  │
│  │  │  - OrdersPage (Status & Verification)        │  │  │
│  │  │  - ResultBox, LoadingSpinner                 │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  Routing Layer (React Router v6)            │  │  │
│  │  │  - Route definitions                         │  │  │
│  │  │  - Navigation state management               │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  API Integration Layer                       │  │  │
│  │  │  - Axios instance with base config           │  │  │
│  │  │  - API service functions                     │  │  │
│  │  │  - Error interceptors                        │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          │ HTTPS
                          ▼
┌─────────────────────────────────────────────────────────┐
│              AWS Lambda Backend API                      │
│  Base URL: https://rhqxsjqj11.execute-api...            │
│  - POST /create-order                                    │
│  - GET /check-payment-status                             │
│  - POST /verify-payment                                  │
└─────────────────────────────────────────────────────────┘
```

### Application Flow

1. **Initial Load**: React Router renders the appropriate page based on URL
2. **User Interaction**: User fills form and submits
3. **API Request**: Component calls API service function
4. **Loading State**: Component displays loading indicator
5. **Response Handling**: Success displays in ResultBox, errors show error message
6. **State Update**: Component state updates trigger re-render

## Components and Interfaces

### Component Hierarchy

```
App
├── Navbar
│   └── NavLink (React Router)
└── Routes
    ├── HomePage
    │   ├── OrderCreationForm
    │   ├── LoadingSpinner
    │   └── ResultBox
    └── OrdersPage
        ├── TabNavigation
        ├── CheckPaymentStatusTab
        │   ├── StatusCheckForm
        │   ├── LoadingSpinner
        │   └── ResultBox
        └── VerifyPaymentTab
            ├── VerificationForm
            ├── LoadingSpinner
            └── ResultBox
```

### Component Specifications

#### 1. App Component

**Purpose**: Root component managing routing and global layout

**Props**: None

**State**: None (routing state managed by React Router)

**Responsibilities**:
- Render Navbar
- Define route configuration
- Provide application-wide layout structure

```jsx
interface AppProps {}

function App(): JSX.Element
```

#### 2. Navbar Component

**Purpose**: Navigation header with routing links

**Props**: None

**State**: None (active route from React Router)

**Responsibilities**:
- Display navigation links (Home, Orders)
- Highlight active route
- Responsive layout for mobile/desktop

```jsx
interface NavbarProps {}

function Navbar(): JSX.Element
```

**Styling**:
- Fixed/sticky positioning at top
- TailwindCSS: `bg-blue-600 text-white shadow-md`
- Active link: `font-bold underline`
- Responsive: `flex-col md:flex-row`

#### 3. HomePage Component

**Purpose**: Order creation interface

**Props**: None

**State**:
```typescript
{
  amount: string;
  loading: boolean;
  error: string | null;
  result: object | null;
  validationError: string | null;
}
```

**Responsibilities**:
- Render order creation form
- Validate amount input
- Call createOrder API
- Display loading state
- Display result or error

```jsx
interface HomePageProps {}

function HomePage(): JSX.Element
```

**Form Fields**:
- Amount (number input, required, min: 1)

**Validation Rules**:
- Amount must be numeric
- Amount must be greater than 0
- Amount is required

#### 4. OrdersPage Component

**Purpose**: Container for payment status and verification tabs

**Props**: None

**State**:
```typescript
{
  activeTab: 'status' | 'verify';
}
```

**Responsibilities**:
- Manage tab switching
- Render active tab content
- Maintain tab state

```jsx
interface OrdersPageProps {}

function OrdersPage(): JSX.Element
```

#### 5. CheckPaymentStatusTab Component

**Purpose**: Check payment status by order ID

**Props**: None

**State**:
```typescript
{
  orderId: string;
  loading: boolean;
  error: string | null;
  result: object | null;
  validationError: string | null;
}
```

**Responsibilities**:
- Render status check form
- Validate order ID input
- Call checkPaymentStatus API
- Display loading state
- Display result or error

```jsx
interface CheckPaymentStatusTabProps {}

function CheckPaymentStatusTab(): JSX.Element
```

**Form Fields**:
- Order ID (text input, required)

**Validation Rules**:
- Order ID is required
- Order ID must not be empty string

#### 6. VerifyPaymentTab Component

**Purpose**: Verify payment signature

**Props**: None

**State**:
```typescript
{
  orderId: string;
  paymentId: string;
  signature: string;
  loading: boolean;
  error: string | null;
  result: object | null;
  validationErrors: {
    orderId?: string;
    paymentId?: string;
    signature?: string;
  };
}
```

**Responsibilities**:
- Render verification form
- Validate all input fields
- Call verifyPayment API
- Display loading state
- Display result or error

```jsx
interface VerifyPaymentTabProps {}

function VerifyPaymentTab(): JSX.Element
```

**Form Fields**:
- Order ID (text input, required)
- Payment ID (text input, required)
- Signature (text input, required)

**Validation Rules**:
- All fields are required
- All fields must not be empty strings

#### 7. ResultBox Component

**Purpose**: Display formatted JSON API responses

**Props**:
```typescript
{
  data: object | null;
  title?: string;
}
```

**State**:
```typescript
{
  copied: boolean;
}
```

**Responsibilities**:
- Format JSON with indentation
- Provide syntax highlighting
- Copy to clipboard functionality
- Display copy confirmation

```jsx
interface ResultBoxProps {
  data: object | null;
  title?: string;
}

function ResultBox({ data, title }: ResultBoxProps): JSX.Element | null
```

**Features**:
- JSON.stringify with 2-space indentation
- Scrollable container with max-height
- Copy button with success feedback
- Conditional rendering (null if no data)

**Styling**:
- Border with rounded corners
- Monospace font for JSON
- Background: `bg-gray-50`
- Border: `border-gray-300`

#### 8. LoadingSpinner Component

**Purpose**: Visual loading indicator

**Props**: None

**State**: None

**Responsibilities**:
- Display animated spinner
- Accessible loading announcement

```jsx
interface LoadingSpinnerProps {}

function LoadingSpinner(): JSX.Element
```

**Implementation**:
- CSS animation or TailwindCSS animate-spin
- ARIA role="status" with sr-only text
- Centered positioning

## Data Models

### API Request Models

#### CreateOrderRequest
```typescript
interface CreateOrderRequest {
  amount: number; // Amount in smallest currency unit (paise for INR)
}
```

#### CheckPaymentStatusRequest
```typescript
interface CheckPaymentStatusRequest {
  orderId: string; // Razorpay order ID
}
```

#### VerifyPaymentRequest
```typescript
interface VerifyPaymentRequest {
  orderId: string;      // Razorpay order ID
  paymentId: string;    // Razorpay payment ID
  signature: string;    // Payment signature for verification
}
```

### API Response Models

#### CreateOrderResponse
```typescript
interface CreateOrderResponse {
  success: boolean;
  orderId: string;
  amount: number;
  currency: string;
  receipt?: string;
  status: string;
  createdAt: number;
}
```

#### CheckPaymentStatusResponse
```typescript
interface CheckPaymentStatusResponse {
  success: boolean;
  orderId: string;
  status: string; // 'created' | 'authorized' | 'captured' | 'failed'
  amount: number;
  amountPaid: number;
  currency: string;
  attempts: number;
  notes?: object;
}
```

#### VerifyPaymentResponse
```typescript
interface VerifyPaymentResponse {
  success: boolean;
  verified: boolean;
  message: string;
  orderId?: string;
  paymentId?: string;
}
```

#### ErrorResponse
```typescript
interface ErrorResponse {
  success: false;
  error: string;
  message: string;
  statusCode?: number;
}
```

### Component State Models

#### FormState (Generic)
```typescript
interface FormState<T> {
  formData: T;
  loading: boolean;
  error: string | null;
  result: object | null;
  validationErrors: Partial<Record<keyof T, string>>;
}
```

### API Configuration

```typescript
interface ApiConfig {
  baseURL: string;
  timeout: number;
  headers: {
    'Content-Type': string;
  };
}

const API_CONFIG: ApiConfig = {
  baseURL: 'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan',
  timeout: 30000, // 30 seconds
  headers: {
    'Content-Type': 'application/json',
  },
};
```

## API Integration Layer

### Axios Instance Configuration

```typescript
// src/api/axiosInstance.ts
import axios, { AxiosInstance, AxiosError } from 'axios';

const axiosInstance: AxiosInstance = axios.create({
  baseURL: 'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Response interceptor for error handling
axiosInstance.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response) {
      // Server responded with error status
      return Promise.reject({
        message: error.response.data?.message || 'Server error occurred',
        statusCode: error.response.status,
        data: error.response.data,
      });
    } else if (error.request) {
      // Request made but no response
      return Promise.reject({
        message: 'Network error: No response from server',
        statusCode: 0,
      });
    } else {
      // Error in request setup
      return Promise.reject({
        message: error.message || 'Request failed',
        statusCode: 0,
      });
    }
  }
);

export default axiosInstance;
```

### API Service Functions

```typescript
// src/api/paymentService.ts
import axiosInstance from './axiosInstance';
import {
  CreateOrderRequest,
  CreateOrderResponse,
  CheckPaymentStatusRequest,
  CheckPaymentStatusResponse,
  VerifyPaymentRequest,
  VerifyPaymentResponse,
} from '../types/api';

export const paymentService = {
  createOrder: async (data: CreateOrderRequest): Promise<CreateOrderResponse> => {
    const response = await axiosInstance.post('/create-order', data);
    return response.data;
  },

  checkPaymentStatus: async (orderId: string): Promise<CheckPaymentStatusResponse> => {
    const response = await axiosInstance.get('/check-payment-status', {
      params: { orderId },
    });
    return response.data;
  },

  verifyPayment: async (data: VerifyPaymentRequest): Promise<VerifyPaymentResponse> => {
    const response = await axiosInstance.post('/verify-payment', data);
    return response.data;
  },
};
```

### Error Handling Strategy

**Error Types**:
1. **Network Errors**: No response from server (timeout, connection refused)
2. **HTTP Errors**: 4xx/5xx status codes from backend
3. **Validation Errors**: Client-side form validation failures
4. **Parsing Errors**: Invalid JSON responses

**Error Handling Approach**:

1. **API Layer**: Axios interceptor catches and normalizes all errors
2. **Component Layer**: Try-catch blocks in async handlers
3. **UI Layer**: Error state displayed with appropriate styling

**Error Display Pattern**:
```jsx
{error && (
  <div className="bg-red-50 border border-red-300 text-red-800 px-4 py-3 rounded" role="alert">
    <p className="font-semibold">Error</p>
    <p>{error}</p>
  </div>
)}
```

**Timeout Handling**:
- 30-second timeout configured in Axios
- Timeout errors display user-friendly message
- Retry option available through form re-submission

## Styling Approach

### TailwindCSS Configuration

**Color Palette**:
- Primary: Blue (blue-600, blue-700)
- Success: Green (green-50, green-600)
- Error: Red (red-50, red-600, red-800)
- Neutral: Gray (gray-50, gray-100, gray-300, gray-600)

**Responsive Breakpoints**:
- Mobile: default (< 640px)
- Tablet: md (≥ 768px)
- Desktop: lg (≥ 1024px)

### Component Styling Patterns

#### Form Styling
```css
/* Input fields */
.input-field {
  @apply w-full px-4 py-2 border border-gray-300 rounded-md 
         focus:outline-none focus:ring-2 focus:ring-blue-500 
         focus:border-transparent;
}

/* Buttons */
.btn-primary {
  @apply bg-blue-600 text-white px-6 py-2 rounded-md 
         hover:bg-blue-700 focus:outline-none focus:ring-2 
         focus:ring-blue-500 focus:ring-offset-2 
         disabled:opacity-50 disabled:cursor-not-allowed;
}

/* Error messages */
.error-message {
  @apply text-red-600 text-sm mt-1;
}
```

#### Layout Patterns
```css
/* Container */
.container {
  @apply max-w-7xl mx-auto px-4 sm:px-6 lg:px-8;
}

/* Card */
.card {
  @apply bg-white rounded-lg shadow-md p-6;
}

/* Form container */
.form-container {
  @apply max-w-md mx-auto;
}
```

### Responsive Design Strategy

**Mobile-First Approach**:
1. Base styles for mobile (single column, full width)
2. Tablet adjustments with `md:` prefix
3. Desktop enhancements with `lg:` prefix

**Navbar Responsive Behavior**:
- Mobile: Vertical stack or hamburger menu
- Desktop: Horizontal navigation bar

**Form Responsive Behavior**:
- Mobile: Full-width inputs, stacked layout
- Desktop: Optimized spacing, centered with max-width

**ResultBox Responsive Behavior**:
- Mobile: Full-width, smaller font size
- Desktop: Larger container, better readability

## Routing Configuration

### Route Definitions

```typescript
// src/App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import HomePage from './pages/HomePage';
import OrdersPage from './pages/OrdersPage';

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-gray-100">
        <Navbar />
        <main className="container mx-auto px-4 py-8">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/orders" element={<OrdersPage />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}
```

### Navigation State Management

- Active route determined by React Router's `useLocation` hook
- NavLink component from React Router provides automatic active styling
- No manual state management required for navigation

### Route Guards

Not required for this application (no authentication/authorization)

## State Management

### Component-Level State

**Approach**: React hooks (useState, useEffect) for local component state

**Rationale**: 
- Application has simple state requirements
- No shared state between distant components
- Each page manages its own form and API state independently

### State Structure Per Component

**HomePage State**:
```typescript
const [amount, setAmount] = useState<string>('');
const [loading, setLoading] = useState<boolean>(false);
const [error, setError] = useState<string | null>(null);
const [result, setResult] = useState<object | null>(null);
const [validationError, setValidationError] = useState<string | null>(null);
```

**Similar pattern for CheckPaymentStatusTab and VerifyPaymentTab**

### State Update Patterns

**Form Submission Flow**:
```typescript
const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();
  
  // Reset states
  setError(null);
  setResult(null);
  setValidationError(null);
  
  // Validate
  const validation = validateForm();
  if (!validation.isValid) {
    setValidationError(validation.error);
    return;
  }
  
  // API call
  setLoading(true);
  try {
    const response = await apiCall();
    setResult(response);
  } catch (err) {
    setError(err.message);
  } finally {
    setLoading(false);
  }
};
```

## Form Validation

### Validation Strategy

**Client-Side Validation**: Immediate feedback before API calls

**Validation Timing**:
- On submit (primary validation)
- Optional: On blur for individual fields
- Optional: Real-time for specific fields (amount format)

### Validation Functions

```typescript
// src/utils/validation.ts

export const validateAmount = (amount: string): { isValid: boolean; error?: string } => {
  if (!amount || amount.trim() === '') {
    return { isValid: false, error: 'Amount is required' };
  }
  
  const numAmount = parseFloat(amount);
  if (isNaN(numAmount)) {
    return { isValid: false, error: 'Amount must be a valid number' };
  }
  
  if (numAmount <= 0) {
    return { isValid: false, error: 'Amount must be greater than 0' };
  }
  
  return { isValid: true };
};

export const validateOrderId = (orderId: string): { isValid: boolean; error?: string } => {
  if (!orderId || orderId.trim() === '') {
    return { isValid: false, error: 'Order ID is required' };
  }
  
  return { isValid: true };
};

export const validateVerificationForm = (
  orderId: string,
  paymentId: string,
  signature: string
): { isValid: boolean; errors: Record<string, string> } => {
  const errors: Record<string, string> = {};
  
  if (!orderId || orderId.trim() === '') {
    errors.orderId = 'Order ID is required';
  }
  
  if (!paymentId || paymentId.trim() === '') {
    errors.paymentId = 'Payment ID is required';
  }
  
  if (!signature || signature.trim() === '') {
    errors.signature = 'Signature is required';
  }
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
};
```

## Accessibility Implementation

### WCAG 2.1 AA Compliance Strategy

#### 1. Semantic HTML
- Use `<nav>`, `<main>`, `<form>`, `<button>` elements
- Proper heading hierarchy (h1, h2, h3)
- Label elements associated with inputs

#### 2. Keyboard Navigation
- All interactive elements focusable via Tab
- Form submission via Enter key
- Tab navigation order follows visual order
- Focus visible with TailwindCSS focus utilities

#### 3. ARIA Attributes

**Form Labels**:
```jsx
<label htmlFor="amount" className="block text-sm font-medium text-gray-700">
  Amount (in paise)
</label>
<input
  id="amount"
  type="number"
  aria-required="true"
  aria-invalid={!!validationError}
  aria-describedby={validationError ? "amount-error" : undefined}
/>
{validationError && (
  <p id="amount-error" className="error-message" role="alert">
    {validationError}
  </p>
)}
```

**Loading States**:
```jsx
<div role="status" aria-live="polite">
  <LoadingSpinner />
  <span className="sr-only">Loading...</span>
</div>
```

**Error Messages**:
```jsx
<div role="alert" aria-live="assertive" className="error-container">
  {error}
</div>
```

**Result Display**:
```jsx
<div role="region" aria-label="API Response">
  <ResultBox data={result} />
</div>
```

#### 4. Focus Management

**Focus Indicators**:
```css
.focus-visible {
  @apply focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2;
}
```

**Skip Links** (optional enhancement):
```jsx
<a href="#main-content" className="sr-only focus:not-sr-only">
  Skip to main content
</a>
```

#### 5. Color Contrast

**Minimum Ratios**:
- Normal text: 4.5:1
- Large text: 3:1
- UI components: 3:1

**TailwindCSS Color Choices**:
- Text on white: `text-gray-900` (21:1 ratio)
- Primary button: `bg-blue-600 text-white` (4.5:1 ratio)
- Error text: `text-red-800` on `bg-red-50` (sufficient contrast)

#### 6. Screen Reader Support

**Visually Hidden Text**:
```css
.sr-only {
  @apply absolute w-px h-px p-0 -m-px overflow-hidden whitespace-nowrap border-0;
}
```

**Descriptive Button Text**:
```jsx
<button type="submit" aria-label="Create payment order">
  Create Order
</button>

<button type="button" aria-label="Copy JSON response to clipboard">
  Copy
</button>
```

## Testing Strategy

### Testing Approach

The application will use a dual testing strategy combining unit tests for specific scenarios and property-based tests for universal behaviors.

### Testing Tools

- **Unit Testing**: Vitest (Vite-native test runner)
- **Property-Based Testing**: fast-check (JavaScript/TypeScript PBT library)
- **React Testing**: @testing-library/react
- **User Interaction**: @testing-library/user-event

### Unit Testing Strategy

**Focus Areas**:
1. Component rendering with different props
2. Form submission handlers
3. Validation functions
4. Error boundary cases
5. API service functions (mocked)
6. User interactions (clicks, form inputs)

**Example Unit Tests**:
```typescript
// Validation function tests
describe('validateAmount', () => {
  it('should reject empty amount', () => {
    expect(validateAmount('')).toEqual({ isValid: false, error: expect.any(String) });
  });
  
  it('should reject negative amount', () => {
    expect(validateAmount('-100')).toEqual({ isValid: false, error: expect.any(String) });
  });
  
  it('should accept valid positive amount', () => {
    expect(validateAmount('1000')).toEqual({ isValid: true });
  });
});

// Component rendering tests
describe('ResultBox', () => {
  it('should render null when data is null', () => {
    const { container } = render(<ResultBox data={null} />);
    expect(container.firstChild).toBeNull();
  });
  
  it('should display formatted JSON when data is provided', () => {
    const data = { orderId: 'order_123', amount: 1000 };
    const { getByText } = render(<ResultBox data={data} />);
    expect(getByText(/"orderId": "order_123"/)).toBeInTheDocument();
  });
});
```

### Property-Based Testing Strategy

**Library**: fast-check (JavaScript/TypeScript property-based testing library)

**Configuration**: Minimum 100 iterations per property test

**Property Test Tagging**: Each test must reference its design property
```typescript
// Feature: razorpay-payment-dashboard, Property 1: Order Creation API Request
```

**Implementation Approach**:

Each correctness property from the design document must be implemented as a single property-based test. The test should:
1. Generate random valid inputs using fast-check arbitraries
2. Execute the system behavior
3. Assert the property holds for all generated inputs

**Example Property Test**:
```typescript
import fc from 'fast-check';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { HomePage } from './HomePage';

// Feature: razorpay-payment-dashboard, Property 1: Order Creation API Request
describe('Property 1: Order Creation API Request', () => {
  it('should send POST to /create-order with amount for any valid amount', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 1, max: 1000000 }), // Generate random valid amounts
        async (amount) => {
          const mockPost = vi.fn().mockResolvedValue({ data: { orderId: 'test' } });
          vi.spyOn(axios, 'post').mockImplementation(mockPost);
          
          render(<HomePage />);
          const input = screen.getByLabelText(/amount/i);
          const button = screen.getByRole('button', { name: /create order/i });
          
          await userEvent.type(input, amount.toString());
          await userEvent.click(button);
          
          await waitFor(() => {
            expect(mockPost).toHaveBeenCalledWith(
              '/create-order',
              { amount },
              expect.any(Object)
            );
          });
        }
      ),
      { numRuns: 100 }
    );
  });
});
```

**Property Test Coverage**:

The following properties require property-based tests:

1. **API Request Properties** (Properties 1-3): Test with random valid inputs
2. **Response Display Properties** (Properties 4-5): Test with random response shapes
3. **Loading State Properties** (Properties 6-7): Test state transitions with random delays
4. **Copy Functionality** (Property 8): Test with random data objects
5. **JSON Formatting** (Property 9): Test with random object structures
6. **Navigation Properties** (Properties 10-11): Test with random route sequences
7. **Validation Properties** (Properties 12-13): Test with random invalid inputs
8. **API Configuration Properties** (Properties 14-15): Test with random endpoints
9. **Accessibility Properties** (Properties 16-20): Test with random component states

**Generators (Arbitraries)**:

```typescript
// Custom arbitraries for domain-specific data
const amountArbitrary = fc.integer({ min: 1, max: 10000000 });
const orderIdArbitrary = fc.string({ minLength: 10, maxLength: 30 });
const paymentIdArbitrary = fc.string({ minLength: 10, maxLength: 30 });
const signatureArbitrary = fc.hexaString({ minLength: 32, maxLength: 64 });

const apiResponseArbitrary = fc.record({
  success: fc.boolean(),
  orderId: orderIdArbitrary,
  amount: amountArbitrary,
  status: fc.constantFrom('created', 'authorized', 'captured', 'failed'),
});

const errorResponseArbitrary = fc.record({
  success: fc.constant(false),
  error: fc.string(),
  message: fc.string(),
  statusCode: fc.integer({ min: 400, max: 599 }),
});
```

**Focus Areas**:
1. Form validation across all possible inputs (valid and invalid)
2. API response handling for various response shapes
3. State transitions during async operations
4. JSON formatting and parsing with diverse object structures
5. Clipboard operations with various data types
6. Error handling with different error scenarios
7. Navigation state with different route combinations

### Integration Testing

**API Integration Tests** (with mocked backend):
- Test complete user flows (form fill → submit → result display)
- Test error scenarios (network failures, 4xx/5xx responses)
- Test loading states during async operations

**Routing Tests**:
- Test navigation between pages
- Test active link highlighting
- Test direct URL access to routes

### Accessibility Testing

**Automated Tests**:
- jest-axe for WCAG violations
- Test keyboard navigation paths
- Test ARIA attribute presence

**Manual Testing Checklist**:
- Screen reader testing (NVDA/JAWS/VoiceOver)
- Keyboard-only navigation
- Color contrast verification
- Focus indicator visibility

### Test Coverage Goals

- **Unit Test Coverage**: 80%+ for utility functions and validation
- **Component Coverage**: 70%+ for React components
- **Integration Coverage**: Key user flows covered
- **Property Test Coverage**: All validation and data transformation logic



## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Order Creation API Request

For any valid amount value, when the user submits the order creation form, the Dashboard should send a POST request to the /create-order endpoint with the amount in the request body.

**Validates: Requirements 2.2**

### Property 2: Payment Status API Request

For any order ID value, when the user submits the status check form, the Dashboard should send a GET request to the /check-payment-status endpoint with the order ID as a query parameter.

**Validates: Requirements 3.3**

### Property 3: Payment Verification API Request

For any combination of order ID, payment ID, and signature values, when the user submits the verification form, the Dashboard should send a POST request to the /verify-payment endpoint with all three values in the request body.

**Validates: Requirements 4.3**

### Property 4: Successful Response Display

For any successful API response from any endpoint, the Dashboard should display the response data in a ResultBox component with formatted JSON.

**Validates: Requirements 2.3, 3.4, 4.4**

### Property 5: Error Response Display

For any error response (network failure, HTTP 4xx/5xx, or timeout), the Dashboard should display an error message to the user describing the failure.

**Validates: Requirements 2.4, 3.5, 4.5, 7.1, 7.2**

### Property 6: Loading State During Async Operations

For any API request in progress, the Dashboard should display a loading indicator and disable the submit button to prevent duplicate submissions.

**Validates: Requirements 2.5, 3.6, 4.6, 8.1, 8.2**

### Property 7: Loading State Cleanup After Completion

For any API request that completes (success or error), the Dashboard should hide the loading indicator and re-enable the submit button.

**Validates: Requirements 8.3, 8.4**

### Property 8: Copy to Clipboard Functionality

For any data object displayed in ResultBox, when the user clicks the copy button, the formatted JSON should be copied to the system clipboard and a confirmation message should be displayed.

**Validates: Requirements 2.6, 6.5**

### Property 9: JSON Formatting

For any API response data object, the ResultBox should format it as indented JSON with 2-space indentation.

**Validates: Requirements 6.2**

### Property 10: SPA Navigation Without Reload

For any navigation link in the Navbar, when clicked, the Dashboard should route to the corresponding page without triggering a full page reload.

**Validates: Requirements 5.2**

### Property 11: Active Route Highlighting

For any active route, the corresponding navigation link in the Navbar should be visually highlighted to indicate the current page.

**Validates: Requirements 5.3**

### Property 12: Non-Numeric Amount Validation

For any amount input containing non-numeric characters, the Dashboard should display a validation error and prevent form submission.

**Validates: Requirements 11.2**

### Property 13: Required Field Validation

For any required form field that is empty, the Dashboard should prevent form submission and display a validation error for that field.

**Validates: Requirements 11.5**

### Property 14: API URL Construction

For any API request, the Dashboard should construct the endpoint URL using the configured base URL constant.

**Validates: Requirements 12.2**

### Property 15: JSON Content-Type Headers

For any API request, the Dashboard should include the "Content-Type: application/json" header.

**Validates: Requirements 12.4**

### Property 16: Interactive Element ARIA Labels

For any interactive element (button, input, link), the Dashboard should provide appropriate ARIA labels for screen reader accessibility.

**Validates: Requirements 10.1**

### Property 17: Keyboard Navigation Support

For any form or button in the Dashboard, it should be accessible and operable via keyboard navigation (Tab, Enter, Space keys).

**Validates: Requirements 10.2**

### Property 18: Focus Indicators

For any focusable element, when it receives keyboard focus, the Dashboard should display a visible focus indicator.

**Validates: Requirements 10.3**

### Property 19: Semantic HTML Structure

For any page or component, the Dashboard should use semantic HTML elements (nav, main, form, button, label) for proper structure and screen reader interpretation.

**Validates: Requirements 10.4**

### Property 20: Error Announcement to Screen Readers

For any error that occurs, the Dashboard should announce the error to screen readers using ARIA live regions.

**Validates: Requirements 10.5**

## Error Handling

### Error Categories and Handling

#### 1. Network Errors

**Scenario**: Request fails to reach the server (connection refused, DNS failure, no internet)

**Detection**: Axios interceptor catches errors where `error.request` exists but `error.response` does not

**Handling**:
- Display user-friendly message: "Network error: Unable to connect to server"
- Log technical details to console for debugging
- Keep form enabled for retry
- Clear loading state

**User Experience**:
```jsx
<div className="bg-red-50 border border-red-300 text-red-800 px-4 py-3 rounded" role="alert">
  <p className="font-semibold">Connection Error</p>
  <p>Unable to connect to the server. Please check your internet connection and try again.</p>
</div>
```

#### 2. HTTP Error Responses (4xx/5xx)

**Scenario**: Server responds with error status code

**Detection**: Axios interceptor catches errors where `error.response` exists

**Handling**:
- Extract error message from response body (`error.response.data.message` or `error.response.data.error`)
- Display server-provided error message to user
- Include status code in console log
- Keep form enabled for retry
- Clear loading state

**Common Status Codes**:
- 400 Bad Request: Invalid input data
- 404 Not Found: Order ID doesn't exist
- 500 Internal Server Error: Backend processing failure

**User Experience**:
```jsx
<div className="bg-red-50 border border-red-300 text-red-800 px-4 py-3 rounded" role="alert">
  <p className="font-semibold">Error</p>
  <p>{errorMessage}</p>
</div>
```

#### 3. Timeout Errors

**Scenario**: Request takes longer than 30 seconds

**Detection**: Axios timeout configuration triggers error

**Handling**:
- Display timeout-specific message
- Suggest user retry or check backend status
- Keep form enabled for retry
- Clear loading state

**User Experience**:
```jsx
<div className="bg-red-50 border border-red-300 text-red-800 px-4 py-3 rounded" role="alert">
  <p className="font-semibold">Request Timeout</p>
  <p>The request took too long to complete. Please try again.</p>
</div>
```

#### 4. Validation Errors

**Scenario**: Client-side form validation fails

**Detection**: Validation functions return `isValid: false`

**Handling**:
- Prevent form submission
- Display field-specific error messages below inputs
- Keep submit button enabled (validation happens on submit)
- Focus first invalid field

**User Experience**:
```jsx
<div className="mt-1">
  <input
    className="border-red-300 focus:ring-red-500"
    aria-invalid="true"
    aria-describedby="amount-error"
  />
  <p id="amount-error" className="text-red-600 text-sm mt-1" role="alert">
    Amount must be greater than 0
  </p>
</div>
```

#### 5. Unexpected Errors

**Scenario**: JavaScript runtime errors, unexpected exceptions

**Detection**: Try-catch blocks in async handlers

**Handling**:
- Display generic error message
- Log full error to console
- Keep form enabled for retry
- Clear loading state

**User Experience**:
```jsx
<div className="bg-red-50 border border-red-300 text-red-800 px-4 py-3 rounded" role="alert">
  <p className="font-semibold">Unexpected Error</p>
  <p>Something went wrong. Please try again.</p>
</div>
```

### Error State Management

**State Structure**:
```typescript
const [error, setError] = useState<string | null>(null);
const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});
```

**Error Clearing Strategy**:
- Clear errors when user starts new submission
- Clear errors when user modifies form inputs (optional enhancement)
- Clear errors when navigating away from page

**Error Recovery**:
- All errors allow immediate retry
- Form remains functional after errors
- No error states persist across navigation

### Error Logging

**Development**:
```typescript
console.error('API Error:', {
  endpoint: '/create-order',
  statusCode: error.statusCode,
  message: error.message,
  data: error.data,
});
```

**Production**:
- Consider integration with error tracking service (Sentry, LogRocket)
- Log errors with context (user action, timestamp, request details)
- Avoid logging sensitive data (payment IDs, signatures)

