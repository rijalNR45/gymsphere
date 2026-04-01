import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { supabase } from "../supabaseClient.js";
export default function Dashboard() {
  const { profile, signOut } = useAuth();
  const [classes, setClasses] = useState([]);
  const [error, setError] = useState(null);
  useEffect(() => {
    fetchClasses();
  }, []);
  async function fetchClasses() {
    try {
      const { data, error } = await supabase
        .from("classes")
        .select("*")
        .order("schedule", { ascending: true });
      if (error) throw error;
      setClasses(data);
    } catch (err) {
      setError(err.message);
    }
  }
  //this section is added later on any is not included in the guide
  async function bookClass(classId) {
    try {
      const { data: memberData, error: memberError } = await supabase
        .from("members")
        .select("id")
        .eq("profile_id", profile.id)
        .single();

      if (memberError) throw memberError;

      const { error: bookingError } = await supabase
        .from("bookings")
        .insert({ class_id: classId, member_id: memberData.id });

      if (bookingError) throw bookingError;
      alert("Class booked successfully!");
    } catch (err) {
      setError(err.message);
    }
  }
  //ends here

  return (
    <div>
      <h1>Welcome, {profile?.full_name}</h1>
      <p>Role: {profile?.role}</p>
      {/* Only show admin link to admins */}
      {profile?.role === "admin" && <a href="/admin">Go to Admin Panel</a>}
      {/* Only show manage classes to trainers and admins */}
      {["admin", "trainer"].includes(profile?.role) && (
        <a href="/classes/manage">Manage Classes</a>
      )}
      <h2>Available Classes</h2>
      {error && <p style={{ color: "red" }}>{error}</p>}
      {classes.map((cls) => (
        <div key={cls.id}>
          <h3>{cls.title}</h3>
          <p>{cls.description}</p>
          {/* Members can book */}
          {profile?.role === "member" && (
            <button onClick={() => bookClass(cls.id)}>Book</button>
          )}
        </div>
      ))}
      <button onClick={signOut}>Sign Out</button>
    </div>
  );
}
