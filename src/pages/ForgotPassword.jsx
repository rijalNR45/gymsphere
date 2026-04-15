import { useState } from "react";
import { supabase } from "../supabaseClient";
import { Link, useNavigate } from "react-router-dom";
import { Dumbbell, Mail, KeyRound, Lock, Loader2, ArrowLeft, CheckCircle } from "lucide-react";

const STEP_EMAIL = "email";
const STEP_OTP = "otp";
const STEP_NEW_PASSWORD = "new_password";

export default function ForgotPassword() {
  const navigate = useNavigate();
  const [step, setStep] = useState(STEP_EMAIL);
  const [email, setEmail] = useState("");
  const [otpCode, setOtpCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  async function handleSendOtp(e) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(email);
      if (resetError) throw resetError;
      setStep(STEP_OTP);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleVerifyOtp(e) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const { error: verifyError } = await supabase.auth.verifyOtp({
        email,
        token: otpCode,
        type: "recovery",
      });
      if (verifyError) throw verifyError;
      setStep(STEP_NEW_PASSWORD);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleUpdatePassword(e) {
    e.preventDefault();
    setError(null);

    if (newPassword !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }
    if (newPassword.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }

    setLoading(true);
    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password: newPassword,
      });
      if (updateError) throw updateError;
      await supabase.auth.signOut();
      navigate("/login", {
        state: { message: "Password reset successful. Sign in with your new password." },
      });
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  const stepConfig = {
    [STEP_EMAIL]: {
      title: "Reset your password",
      subtitle: "Enter your email and we'll send you a verification code",
      onSubmit: handleSendOtp,
    },
    [STEP_OTP]: {
      title: "Check your email",
      subtitle: `We sent a 6-digit code to ${email}`,
      onSubmit: handleVerifyOtp,
    },
    [STEP_NEW_PASSWORD]: {
      title: "Set new password",
      subtitle: "Choose a strong password for your account",
      onSubmit: handleUpdatePassword,
    },
  };

  const current = stepConfig[step];

  return (
    <div className="flex min-h-screen">
      <div className="hidden lg:flex lg:w-1/2 bg-sidebar items-center justify-center p-16">
        <div className="max-w-md text-center">
          <Dumbbell className="mx-auto h-16 w-16 text-primary mb-8" />
          <h1 className="text-3xl font-bold text-white mb-4">GymSphere</h1>
          <p className="text-gray-400 text-lg leading-relaxed">
            Don&apos;t worry, it happens to the best of us. We&apos;ll help you
            get back into your account.
          </p>
        </div>
      </div>

      <div className="flex w-full items-center justify-center px-6 lg:w-1/2">
        <div className="w-full max-w-sm">
          <div className="mb-10 lg:hidden flex items-center justify-center gap-3">
            <Dumbbell className="h-8 w-8 text-primary" />
            <span className="text-2xl font-bold text-text-primary">GymSphere</span>
          </div>

          <Link
            to="/login"
            className="mb-6 inline-flex items-center gap-1.5 text-sm text-text-secondary hover:text-text-primary"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to sign in
          </Link>

          <h2 className="text-2xl font-bold text-text-primary leading-tight">
            {current.title}
          </h2>
          <p className="mt-2 text-sm text-text-secondary">
            {current.subtitle}
          </p>

          {error && (
            <div className="mt-5 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-danger leading-normal">
              {error}
            </div>
          )}

          <form onSubmit={current.onSubmit} className="mt-8 space-y-5">
            {step === STEP_EMAIL && (
              <div>
                <label className="block text-sm font-medium text-text-primary mb-2">
                  Email address
                </label>
                <div className="relative">
                  <Mail className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    required
                    className="w-full rounded-lg border border-border bg-surface py-3 pl-10 pr-4 text-sm text-text-primary placeholder:text-text-muted focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
              </div>
            )}

            {step === STEP_OTP && (
              <div>
                <label className="block text-sm font-medium text-text-primary mb-2">
                  Verification code
                </label>
                <div className="relative">
                  <KeyRound className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
                  <input
                    type="text"
                    value={otpCode}
                    onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    placeholder="Enter 6-digit code"
                    required
                    maxLength={6}
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    className="w-full rounded-lg border border-border bg-surface py-3 pl-10 pr-4 text-sm text-text-primary placeholder:text-text-muted focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary tracking-widest"
                  />
                </div>
                <button
                  type="button"
                  onClick={handleSendOtp}
                  disabled={loading}
                  className="mt-2 text-xs font-medium text-primary hover:text-primary-hover disabled:opacity-50"
                >
                  Resend code
                </button>
              </div>
            )}

            {step === STEP_NEW_PASSWORD && (
              <>
                <div>
                  <label className="block text-sm font-medium text-text-primary mb-2">
                    New password
                  </label>
                  <div className="relative">
                    <Lock className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
                    <input
                      type="password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      placeholder="Enter new password"
                      required
                      minLength={6}
                      className="w-full rounded-lg border border-border bg-surface py-3 pl-10 pr-4 text-sm text-text-primary placeholder:text-text-muted focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                    />
                  </div>
                  <p className="mt-1.5 text-xs text-text-muted">
                    Must be at least 6 characters
                  </p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-text-primary mb-2">
                    Confirm password
                  </label>
                  <div className="relative">
                    <CheckCircle className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
                    <input
                      type="password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Confirm new password"
                      required
                      minLength={6}
                      className="w-full rounded-lg border border-border bg-surface py-3 pl-10 pr-4 text-sm text-text-primary placeholder:text-text-muted focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                    />
                  </div>
                </div>
              </>
            )}

            <button
              type="submit"
              disabled={loading}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-primary px-4 py-3 text-sm font-semibold text-white hover:bg-primary-hover disabled:opacity-50 disabled:cursor-not-allowed mt-2"
            >
              {loading && <Loader2 className="h-4 w-4 animate-spin" />}
              {step === STEP_EMAIL && (loading ? "Sending..." : "Send Verification Code")}
              {step === STEP_OTP && (loading ? "Verifying..." : "Verify Code")}
              {step === STEP_NEW_PASSWORD && (loading ? "Updating..." : "Reset Password")}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
