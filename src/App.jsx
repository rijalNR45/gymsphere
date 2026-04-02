import { Routes, Route, Navigate } from "react-router-dom";
import ProtectedRoute from "./components/ProtectedRoute";
import Login from "./pages/Login";
import Signup from "./pages/Signup";
import Dashboard from "./pages/Dashboard";
import AdminPanel from "./pages/AdminPanel";
import ManageClasses from "./pages/ManageClasses";
import MyBookings from "./pages/MyBookings";
import Members from "./pages/Members";
import Trainers from "./pages/Trainers";
import Profile from "./pages/Profile";
import Unauthorized from "./pages/Unauthorized";

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/dashboard" replace />} />

      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/unauthorized" element={<Unauthorized />} />

      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        }
      />

      <Route
        path="/profile"
        element={
          <ProtectedRoute>
            <Profile />
          </ProtectedRoute>
        }
      />

      <Route
        path="/my-bookings"
        element={
          <ProtectedRoute allowedRoles={["member"]}>
            <MyBookings />
          </ProtectedRoute>
        }
      />

      <Route
        path="/classes/manage"
        element={
          <ProtectedRoute allowedRoles={["admin", "trainer"]}>
            <ManageClasses />
          </ProtectedRoute>
        }
      />

      <Route
        path="/members"
        element={
          <ProtectedRoute allowedRoles={["admin"]}>
            <Members />
          </ProtectedRoute>
        }
      />

      <Route
        path="/trainers"
        element={
          <ProtectedRoute allowedRoles={["admin"]}>
            <Trainers />
          </ProtectedRoute>
        }
      />

      <Route
        path="/admin"
        element={
          <ProtectedRoute allowedRoles={["admin"]}>
            <AdminPanel />
          </ProtectedRoute>
        }
      />

      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}
