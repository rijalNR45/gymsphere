import { Routes, Route } from "react-router-dom";
import ProtectedRoute from "./components/ProtectedRoute";
import Login from "./pages/Login";
import Signup from "./pages/Signup";
import Dashboard from "./pages/Dashboard";
// import AdminPanel from "./pages/AdminPanel";
// import ManageClasses from "./pages/ManageClasses";
// import Unauthorized from "./pages/Unauthorized";
export default function App() {
  return (
    <Routes>
      {/* Public routes */}
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/unauthorized" element={<Unauthorized />} />
      {/* Any logged-in user */}
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        }
      />
      {/* Admin only */}
      <Route
        path="/admin"
        element={
          <ProtectedRoute allowedRoles={["admin"]}>
            <AdminPanel />
          </ProtectedRoute>
        }
      />
      {/* Admin and trainer */}
      <Route
        path="/classes/manage"
        element={
          <ProtectedRoute allowedRoles={["admin", "trainer"]}>
            <ManageClasses />
          </ProtectedRoute>
        }
      />
    </Routes>
  );
}
