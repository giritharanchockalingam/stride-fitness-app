import { useState, useEffect, useRef, useMemo, useCallback, createContext, useContext } from "react";
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Tooltip } from "recharts";
import {
  Home, Activity, Dumbbell, Trophy, User, ChevronRight, ChevronLeft, Flame, Footprints,
  Heart, Clock, TrendingUp, Zap, MapPin, Play, Pause, Check, Plus, Bell,
  Settings, Award, Users, Calendar, BarChart3, Target, ArrowUp, ArrowRight,
  Timer, Route, Mountain, Waves, Bike, PersonStanding, Sun, Moon, Search,
  Filter, MoreHorizontal, Share2, MessageCircle, ThumbsUp, Sparkles, Crown,
  Medal, Star, ChevronDown, X, LogOut, Edit3, Camera, Mail, Lock, Eye, EyeOff, Loader2, RefreshCw, Save
} from "lucide-react";

// ============================================
// SUPABASE CLIENT (lightweight, no external SDK)
// ============================================
const SUPABASE_URL = "https://ecylmwvutlxgqivhrxdc.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjeWxtd3Z1dGx4Z3FpdmhyeGRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNjM2MTYsImV4cCI6MjA4ODYzOTYxNn0.PPa9l51-S35-lMYvtQi_0MP-s41WeN1y686BuBBX-GE";

const supabaseHeaders = (token) => ({
  "Content-Type": "application/json",
  apikey: SUPABASE_KEY,
  Authorization: `Bearer ${token || SUPABASE_KEY}`,
});

const supabase = {
  // Auth
  async signUp(email, password, fullName) {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
      method: "POST",
      headers: { "Content-Type": "application/json", apikey: SUPABASE_KEY },
      body: JSON.stringify({ email, password, data: { full_name: fullName } }),
    });
    return res.json();
  },
  async signIn(email, password) {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
      method: "POST",
      headers: { "Content-Type": "application/json", apikey: SUPABASE_KEY },
      body: JSON.stringify({ email, password }),
    });
    return res.json();
  },
  async getUser(token) {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${token}` },
    });
    return res.json();
  },
  signInWithGoogle() {
    const redirectTo = window.location.origin;
    window.location.href = `${SUPABASE_URL}/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(redirectTo)}`;
  },
  // REST
  async from(table, token) {
    return {
      async select(columns = "*", filters = "") {
        const url = `${SUPABASE_URL}/rest/v1/${table}?select=${columns}${filters}`;
        const res = await fetch(url, { headers: { ...supabaseHeaders(token), Prefer: "return=representation" } });
        return res.json();
      },
      async insert(data) {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
          method: "POST",
          headers: { ...supabaseHeaders(token), Prefer: "return=representation" },
          body: JSON.stringify(data),
        });
        return res.json();
      },
      async update(data, filters) {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${filters}`, {
          method: "PATCH",
          headers: { ...supabaseHeaders(token), Prefer: "return=representation" },
          body: JSON.stringify(data),
        });
        return res.json();
      },
      async delete(filters) {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${filters}`, {
          method: "DELETE",
          headers: supabaseHeaders(token),
        });
        return res.ok;
      },
      async rpc(fn, params) {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
          method: "POST",
          headers: supabaseHeaders(token),
          body: JSON.stringify(params),
        });
        return res.json();
      },
    };
  },
  async rpc(fn, params, token) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
      method: "POST",
      headers: supabaseHeaders(token),
      body: JSON.stringify(params),
    });
    return res.json();
  },
  async query(table, token, { select = "*", filters = "", order = "", limit = "" } = {}) {
    let url = `${SUPABASE_URL}/rest/v1/${table}?select=${encodeURIComponent(select)}`;
    if (filters) url += `&${filters}`;
    if (order) url += `&order=${order}`;
    if (limit) url += `&limit=${limit}`;
    const res = await fetch(url, { headers: supabaseHeaders(token) });
    if (!res.ok) { const err = await res.json().catch(() => ({})); throw new Error(err.message || res.statusText); }
    return res.json();
  },
  async insert(table, data, token) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
      method: "POST",
      headers: { ...supabaseHeaders(token), Prefer: "return=representation" },
      body: JSON.stringify(data),
    });
    if (!res.ok) { const err = await res.json().catch(() => ({})); throw new Error(err.message || res.statusText); }
    return res.json();
  },
  async update(table, data, filters, token) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${filters}`, {
      method: "PATCH",
      headers: { ...supabaseHeaders(token), Prefer: "return=representation" },
      body: JSON.stringify(data),
    });
    if (!res.ok) { const err = await res.json().catch(() => ({})); throw new Error(err.message || res.statusText); }
    return res.json();
  },
};

// ============================================
// AUTH CONTEXT
// ============================================
const AuthContext = createContext(null);

const useAuth = () => useContext(AuthContext);

// ============================================
// THEME
// ============================================
const C = {
  bg: "#0a0a0a", bgCard: "#141414", bgHover: "#1a1a1a", bgEl: "#1e1e1e", bgInput: "#1a1a1a",
  pri: "#FC4C02", priL: "#FF6B35", priD: "#D4400A", sec: "#FF9500", acc: "#00D4AA", accB: "#007AFF",
  danger: "#FF3B30", text: "#FFF", text2: "#8E8E93", text3: "#636366",
  bor: "#2C2C2E", borL: "#3A3A3C",
  rMove: "#FC4C02", rExer: "#2DD4BF", rStand: "#007AFF",
};

// ============================================
// UTILITY FUNCTIONS
// ============================================
const formatDuration = (s) => { const h = Math.floor(s/3600), m = Math.floor((s%3600)/60), sec = s%60; return h > 0 ? `${h}h ${m}m` : `${m}:${String(sec).padStart(2,"0")}`; };
const getActivityIcon = (t) => ({ run: Route, walk: Footprints, cycle: Bike, swim: Waves, hike: Mountain, yoga: PersonStanding }[t] || Activity);
const getActivityColor = (t) => ({ run: "#FC4C02", walk: "#2DD4BF", cycle: "#007AFF", swim: "#00D4AA", hike: "#FF9500", yoga: "#AF52DE" }[t] || "#FC4C02");
const timeAgo = (d) => { const s = Math.floor((Date.now() - new Date(d)) / 1000); if (s < 3600) return `${Math.floor(s/60)}m ago`; if (s < 86400) return `${Math.floor(s/3600)}h ago`; return `${Math.floor(s/86400)}d ago`; };
const fmtDate = (d) => new Date(d).toLocaleDateString("en-US", { month: "short", day: "numeric" });

// ============================================
// SHARED COMPONENTS
// ============================================
const ActivityRings = ({ move = 0, exercise = 0, stand = 0, size = 140, sw = 12 }) => {
  const [anim, setAnim] = useState(false);
  useEffect(() => { setTimeout(() => setAnim(true), 300); }, []);
  const rings = [
    { p: anim ? move : 0, c: C.rMove, r: size/2 - sw },
    { p: anim ? exercise : 0, c: C.rExer, r: size/2 - sw*2.5 },
    { p: anim ? stand : 0, c: C.rStand, r: size/2 - sw*4 },
  ];
  return (
    <svg width={size} height={size} style={{ transform: "rotate(-90deg)" }}>
      {rings.map((ring, i) => {
        const circ = 2 * Math.PI * ring.r;
        return (<g key={i}><circle cx={size/2} cy={size/2} r={ring.r} fill="none" stroke={ring.c} strokeWidth={sw} opacity={0.15}/>
          <circle cx={size/2} cy={size/2} r={ring.r} fill="none" stroke={ring.c} strokeWidth={sw}
            strokeDasharray={circ} strokeDashoffset={circ*(1-Math.min(ring.p,1))} strokeLinecap="round"
            style={{ transition: "stroke-dashoffset 1.5s cubic-bezier(0.4,0,0.2,1)", filter: `drop-shadow(0 0 6px ${ring.c}40)` }}/></g>);
      })}
    </svg>
  );
};

const StatCard = ({ icon: Icon, label, value, unit, color, trend, sub }) => (
  <div style={{ background: C.bgCard, borderRadius: 16, padding: 16, border: `1px solid ${C.bor}`, flex: 1, minWidth: 0 }}>
    <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 8 }}>
      <div style={{ width: 32, height: 32, borderRadius: 8, display: "flex", alignItems: "center", justifyContent: "center", background: `${color}15` }}>
        <Icon size={16} color={color} /></div>
      {trend && <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 2 }}>
        <ArrowUp size={12} color={C.acc} /><span style={{ fontSize: 11, color: C.acc, fontWeight: 600 }}>{trend}</span></div>}
    </div>
    <div style={{ fontSize: 24, fontWeight: 700, color: C.text, letterSpacing: -0.5 }}>{value}<span style={{ fontSize: 13, fontWeight: 500, color: C.text2, marginLeft: 2 }}>{unit}</span></div>
    <div style={{ fontSize: 12, color: C.text2, marginTop: 2 }}>{label}</div>
    {sub && <div style={{ fontSize: 11, color: C.text3, marginTop: 2 }}>{sub}</div>}
  </div>
);

const ProgressBar = ({ progress, color, height = 6, showLabel = false }) => (
  <div><div style={{ width: "100%", height, borderRadius: height, background: `${color}20`, overflow: "hidden" }}>
    <div style={{ width: `${Math.min(progress,100)}%`, height: "100%", borderRadius: height, background: color, transition: "width 1s ease" }} /></div>
    {showLabel && <div style={{ fontSize: 11, color: C.text2, marginTop: 4, textAlign: "right" }}>{Math.round(progress)}%</div>}</div>
);

const Loading = ({ text = "Loading..." }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: 60, gap: 12 }}>
    <Loader2 size={28} color={C.pri} style={{ animation: "spin 1s linear infinite" }} />
    <div style={{ fontSize: 14, color: C.text2 }}>{text}</div>
    <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
  </div>
);

const EmptyState = ({ icon: Icon, title, subtitle, action, onAction }) => (
  <div style={{ textAlign: "center", padding: "40px 20px" }}>
    <div style={{ width: 64, height: 64, borderRadius: 32, background: `${C.pri}15`, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px" }}>
      <Icon size={28} color={C.pri} /></div>
    <div style={{ fontSize: 17, fontWeight: 600, color: C.text, marginBottom: 6 }}>{title}</div>
    <div style={{ fontSize: 14, color: C.text2, marginBottom: 16 }}>{subtitle}</div>
    {action && <button onClick={onAction} style={{ padding: "10px 24px", borderRadius: 12, border: "none", background: C.pri, color: "#fff", fontSize: 14, fontWeight: 600, cursor: "pointer" }}>{action}</button>}
  </div>
);

// ============================================
// AUTH SCREEN
// ============================================
const AuthScreen = ({ onAuth }) => {
  const [mode, setMode] = useState("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(""); setLoading(true);
    try {
      if (mode === "signup") {
        const data = await supabase.signUp(email, password, fullName);
        if (data.error) throw new Error(data.error.message || data.error_description || "Sign up failed");
        if (data.access_token) {
          // Auto-seed demo data for new user
          try { await supabase.rpc("seed_demo_data_for_user", { p_user_id: data.user.id }, data.access_token); } catch (e) { console.log("Seed skipped:", e); }
          onAuth(data);
        } else {
          setMode("login");
          setError("Check your email to confirm, then sign in!");
        }
      } else {
        const data = await supabase.signIn(email, password);
        if (data.error) throw new Error(data.error.message || data.error_description || "Sign in failed");
        onAuth(data);
      }
    } catch (err) { setError(err.message); }
    setLoading(false);
  };

  return (
    <div style={{ minHeight: "100vh", background: C.bg, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: 24, fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif" }}>
      {/* Logo */}
      <div style={{ marginBottom: 40, textAlign: "center" }}>
        <div style={{ width: 72, height: 72, borderRadius: 20, background: `linear-gradient(135deg, ${C.pri}, ${C.priL})`, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px", boxShadow: `0 8px 32px ${C.pri}40` }}>
          <Zap size={36} color="#fff" />
        </div>
        <div style={{ fontSize: 32, fontWeight: 800, color: C.text, letterSpacing: -1 }}>STRIDE</div>
        <div style={{ fontSize: 14, color: C.text2, marginTop: 4 }}>Your fitness journey starts here</div>
      </div>

      {/* Form Card */}
      <div style={{ width: "100%", maxWidth: 380, background: C.bgCard, borderRadius: 24, padding: 28, border: `1px solid ${C.bor}` }}>
        <div style={{ fontSize: 22, fontWeight: 700, color: C.text, marginBottom: 4 }}>{mode === "login" ? "Welcome Back" : "Create Account"}</div>
        <div style={{ fontSize: 14, color: C.text2, marginBottom: 24 }}>{mode === "login" ? "Sign in to continue your streak" : "Join the community"}</div>

        {error && <div style={{ background: `${C.danger}15`, border: `1px solid ${C.danger}30`, borderRadius: 12, padding: "10px 14px", marginBottom: 16, fontSize: 13, color: C.danger }}>{error}</div>}

        <form onSubmit={handleSubmit}>
          {mode === "signup" && (
            <div style={{ marginBottom: 14 }}>
              <label style={{ fontSize: 13, color: C.text2, marginBottom: 6, display: "block" }}>Full Name</label>
              <div style={{ display: "flex", alignItems: "center", background: C.bgInput, borderRadius: 12, border: `1px solid ${C.bor}`, padding: "0 14px" }}>
                <User size={16} color={C.text3} />
                <input value={fullName} onChange={(e) => setFullName(e.target.value)} placeholder="Enter your name" required
                  style={{ flex: 1, background: "transparent", border: "none", padding: "12px 10px", color: C.text, fontSize: 15, outline: "none" }} />
              </div>
            </div>
          )}
          <div style={{ marginBottom: 14 }}>
            <label style={{ fontSize: 13, color: C.text2, marginBottom: 6, display: "block" }}>Email</label>
            <div style={{ display: "flex", alignItems: "center", background: C.bgInput, borderRadius: 12, border: `1px solid ${C.bor}`, padding: "0 14px" }}>
              <Mail size={16} color={C.text3} />
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" required
                style={{ flex: 1, background: "transparent", border: "none", padding: "12px 10px", color: C.text, fontSize: 15, outline: "none" }} />
            </div>
          </div>
          <div style={{ marginBottom: 20 }}>
            <label style={{ fontSize: 13, color: C.text2, marginBottom: 6, display: "block" }}>Password</label>
            <div style={{ display: "flex", alignItems: "center", background: C.bgInput, borderRadius: 12, border: `1px solid ${C.bor}`, padding: "0 14px" }}>
              <Lock size={16} color={C.text3} />
              <input type={showPw ? "text" : "password"} value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Min 6 characters" required minLength={6}
                style={{ flex: 1, background: "transparent", border: "none", padding: "12px 10px", color: C.text, fontSize: 15, outline: "none" }} />
              <button type="button" onClick={() => setShowPw(!showPw)} style={{ background: "none", border: "none", cursor: "pointer", padding: 4 }}>
                {showPw ? <EyeOff size={16} color={C.text3} /> : <Eye size={16} color={C.text3} />}
              </button>
            </div>
          </div>
          <button type="submit" disabled={loading} style={{
            width: "100%", padding: "14px", borderRadius: 14, border: "none", cursor: loading ? "wait" : "pointer",
            background: loading ? C.text3 : `linear-gradient(135deg, ${C.pri}, ${C.priL})`,
            color: "#fff", fontSize: 16, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
            boxShadow: loading ? "none" : `0 4px 16px ${C.pri}40`,
          }}>
            {loading && <Loader2 size={18} style={{ animation: "spin 1s linear infinite" }} />}
            {mode === "login" ? "Sign In" : "Create Account"}
          </button>
        </form>

        {/* Divider */}
        <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "20px 0" }}>
          <div style={{ flex: 1, height: 1, background: C.bor }} />
          <span style={{ fontSize: 13, color: C.text3 }}>or</span>
          <div style={{ flex: 1, height: 1, background: C.bor }} />
        </div>

        {/* Google OAuth */}
        <button onClick={() => supabase.signInWithGoogle()} style={{
          width: "100%", padding: "13px", borderRadius: 14, border: `1px solid ${C.bor}`,
          background: C.bgInput, color: C.text, fontSize: 15, fontWeight: 600,
          display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
          cursor: "pointer", transition: "background 0.2s",
        }}>
          <svg width="18" height="18" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
          Continue with Google
        </button>

        <div style={{ textAlign: "center", marginTop: 20 }}>
          <span style={{ fontSize: 14, color: C.text2 }}>{mode === "login" ? "Don't have an account? " : "Already have an account? "}</span>
          <button onClick={() => { setMode(mode === "login" ? "signup" : "login"); setError(""); }}
            style={{ background: "none", border: "none", color: C.pri, fontSize: 14, fontWeight: 600, cursor: "pointer" }}>
            {mode === "login" ? "Sign Up" : "Sign In"}
          </button>
        </div>
      </div>
      <style>{`@keyframes spin { to { transform: rotate(360deg) } } input::placeholder { color: ${C.text3}; }`}</style>
    </div>
  );
};

// ============================================
// DASHBOARD SCREEN (LIVE DATA)
// ============================================
const DashboardScreen = ({ onNavigate }) => {
  const { token, user, profile, refreshProfile } = useAuth();
  const [todayStats, setTodayStats] = useState(null);
  const [weeklyStats, setWeeklyStats] = useState([]);
  const [recentActivities, setRecentActivities] = useState([]);
  const [workoutPlans, setWorkoutPlans] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    setLoading(true);
    try {
      const today = new Date().toISOString().split("T")[0];
      const [stats, weekly, activities, plans] = await Promise.all([
        supabase.query("daily_stats", token, { filters: `user_id=eq.${user.id}&date=eq.${today}`, limit: "1" }),
        supabase.query("daily_stats", token, { filters: `user_id=eq.${user.id}`, order: "date.desc", limit: "7" }),
        supabase.query("activities", token, { filters: `user_id=eq.${user.id}`, order: "started_at.desc", limit: "5" }),
        supabase.query("workout_plans", token, { filters: "is_featured=eq.true", limit: "6" }),
      ]);
      setTodayStats(stats[0] || null);
      setWeeklyStats(weekly.reverse().map(d => ({ day: new Date(d.date).toLocaleDateString("en", { weekday: "short" }), steps: d.total_steps, cal: Math.round(Number(d.total_calories)), mins: d.active_minutes })));
      setRecentActivities(activities);
      setWorkoutPlans(plans);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  if (loading) return <Loading text="Loading dashboard..." />;

  const ts = todayStats || {};
  const stepGoal = profile?.daily_step_goal || 10000;
  const calGoal = profile?.daily_calorie_goal || 500;
  const minGoal = profile?.daily_active_minutes_goal || 30;
  const stepsP = (ts.total_steps || 0) / stepGoal;
  const calP = Number(ts.total_calories || 0) / calGoal;
  const minP = (ts.active_minutes || 0) / minGoal;

  const categoryEmoji = { strength: "💪", hiit: "🔥", flexibility: "🧘", cardio: "🏃", custom: "⚡" };

  return (
    <div style={{ padding: "0 16px 100px" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "16px 0 20px" }}>
        <div>
          <div style={{ fontSize: 14, color: C.text2 }}>Good {new Date().getHours() < 12 ? "morning" : new Date().getHours() < 17 ? "afternoon" : "evening"}</div>
          <div style={{ fontSize: 26, fontWeight: 700, color: C.text, letterSpacing: -0.5 }}>{profile?.full_name || "Athlete"} 👋</div>
        </div>
        <div style={{ display: "flex", gap: 12 }}>
          <button onClick={loadDashboard} style={{ width: 40, height: 40, borderRadius: 20, background: C.bgCard, border: `1px solid ${C.bor}`, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
            <RefreshCw size={16} color={C.text2} /></button>
          <div style={{ width: 40, height: 40, borderRadius: 20, background: C.bgCard, border: `1px solid ${C.bor}`, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", position: "relative" }}
            onClick={() => onNavigate("notifications")}>
            <Bell size={18} color={C.text2} />
          </div>
        </div>
      </div>

      {/* Streak Banner */}
      {profile?.current_streak > 0 && (
        <div style={{ background: `linear-gradient(135deg, ${C.pri}20, ${C.sec}10)`, borderRadius: 16, padding: "16px 20px", marginBottom: 20, border: `1px solid ${C.pri}30`, display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{ fontSize: 36 }}>🔥</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 20, fontWeight: 700, color: C.text }}>{profile.current_streak}-Day Streak</div>
            <div style={{ fontSize: 13, color: C.text2 }}>Personal best: {profile.longest_streak} days</div>
          </div>
        </div>
      )}

      {/* Activity Rings */}
      <div style={{ background: C.bgCard, borderRadius: 20, padding: 24, marginBottom: 20, border: `1px solid ${C.bor}` }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
          <div style={{ fontSize: 17, fontWeight: 600, color: C.text }}>Today's Progress</div>
          <div style={{ fontSize: 13, color: C.pri, fontWeight: 500, cursor: "pointer" }} onClick={() => onNavigate("activity")}>Details →</div>
        </div>
        {todayStats ? (
          <div style={{ display: "flex", alignItems: "center", gap: 24 }}>
            <ActivityRings move={stepsP} exercise={minP} stand={calP} size={130} sw={11} />
            <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 14 }}>
              {[
                { label: "Move", val: `${Math.round(Number(ts.total_calories||0))}`, u: "cal", g: calGoal, c: C.rMove, p: calP },
                { label: "Exercise", val: `${ts.active_minutes||0}`, u: "min", g: minGoal, c: C.rExer, p: minP },
                { label: "Steps", val: (ts.total_steps||0).toLocaleString(), u: "", g: stepGoal, c: C.rStand, p: stepsP },
              ].map(i => (
                <div key={i.label}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                      <div style={{ width: 8, height: 8, borderRadius: 4, background: i.c }} />
                      <span style={{ fontSize: 12, color: C.text2 }}>{i.label}</span>
                    </div>
                    <span style={{ fontSize: 13, fontWeight: 600, color: C.text }}>{i.val}<span style={{ fontSize: 11, color: C.text2 }}> / {i.g.toLocaleString()}{i.u}</span></span>
                  </div>
                  <ProgressBar progress={i.p*100} color={i.c} height={5} />
                </div>
              ))}
            </div>
          </div>
        ) : (
          <EmptyState icon={Target} title="No data yet today" subtitle="Start an activity to track your progress" />
        )}
      </div>

      {/* Quick Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 20 }}>
        <StatCard icon={Footprints} label="Steps" value={(ts.total_steps||0).toLocaleString()} unit="" color={C.pri} />
        <StatCard icon={Flame} label="Calories" value={Math.round(Number(ts.total_calories||0))} unit="kcal" color={C.danger} />
        <StatCard icon={Heart} label="Avg HR" value={ts.avg_heart_rate||"--"} unit="bpm" color="#FF2D55" sub={ts.resting_heart_rate ? `Resting: ${ts.resting_heart_rate}` : ""} />
        <StatCard icon={Route} label="Distance" value={(Number(ts.total_distance_meters||0)/1000).toFixed(1)} unit="km" color={C.accB} />
      </div>

      {/* Weekly Steps Chart */}
      {weeklyStats.length > 0 && (
        <div style={{ background: C.bgCard, borderRadius: 20, padding: 20, marginBottom: 20, border: `1px solid ${C.bor}` }}>
          <div style={{ fontSize: 17, fontWeight: 600, color: C.text, marginBottom: 4 }}>Weekly Steps</div>
          <div style={{ fontSize: 13, color: C.text2, marginBottom: 16 }}>
            Avg: {Math.round(weeklyStats.reduce((a,b) => a+b.steps,0)/weeklyStats.length).toLocaleString()} steps/day
          </div>
          <ResponsiveContainer width="100%" height={160}>
            <BarChart data={weeklyStats} barCategoryGap="25%">
              <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: C.text3, fontSize: 11 }} />
              <YAxis hide /><Tooltip contentStyle={{ background: C.bgEl, border: `1px solid ${C.bor}`, borderRadius: 12, fontSize: 12 }} cursor={{ fill: "transparent" }} />
              <Bar dataKey="steps" fill={C.pri} radius={[6,6,0,0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Recent Activities */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
          <div style={{ fontSize: 17, fontWeight: 600, color: C.text }}>Recent Activities</div>
          <div style={{ fontSize: 13, color: C.pri, fontWeight: 500, cursor: "pointer" }} onClick={() => onNavigate("activity")}>View All</div>
        </div>
        {recentActivities.length === 0 ? (
          <EmptyState icon={Activity} title="No activities yet" subtitle="Log your first activity to see it here" />
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {recentActivities.slice(0,3).map(act => {
              const Icon = getActivityIcon(act.activity_type);
              const color = getActivityColor(act.activity_type);
              return (
                <div key={act.id} style={{ background: C.bgCard, borderRadius: 16, padding: "14px 16px", border: `1px solid ${C.bor}`, display: "flex", alignItems: "center", gap: 14 }}>
                  <div style={{ width: 44, height: 44, borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", background: `${color}15` }}>
                    <Icon size={20} color={color} /></div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 15, fontWeight: 600, color: C.text }}>{act.title || act.activity_type}</div>
                    <div style={{ fontSize: 12, color: C.text2 }}>{timeAgo(act.started_at)}</div>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    {Number(act.distance_meters) > 0 && <div style={{ fontSize: 15, fontWeight: 600, color: C.text }}>{(Number(act.distance_meters)/1000).toFixed(1)} km</div>}
                    <div style={{ fontSize: 12, color: C.text2 }}>{formatDuration(act.duration_seconds || 0)}</div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Featured Workouts */}
      <div>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
          <div style={{ fontSize: 17, fontWeight: 600, color: C.text }}>Featured Workouts</div>
          <div style={{ fontSize: 13, color: C.pri, fontWeight: 500, cursor: "pointer" }} onClick={() => onNavigate("workout")}>Browse All</div>
        </div>
        <div style={{ display: "flex", gap: 12, overflowX: "auto", padding: "0 0 4px" }}>
          {workoutPlans.map(p => (
            <div key={p.id} style={{ minWidth: 160, background: C.bgCard, borderRadius: 16, padding: 16, border: `1px solid ${C.bor}`, flexShrink: 0 }}>
              <div style={{ fontSize: 32, marginBottom: 10 }}>{categoryEmoji[p.category] || "💪"}</div>
              <div style={{ fontSize: 14, fontWeight: 600, color: C.text, marginBottom: 4 }}>{p.title}</div>
              <div style={{ fontSize: 12, color: C.text2 }}>{p.estimated_duration_minutes} min</div>
              <div style={{ display: "inline-block", marginTop: 8, padding: "3px 8px", borderRadius: 6, background: `${C.pri}15`, color: C.pri, fontSize: 11, fontWeight: 600, textTransform: "capitalize" }}>{p.difficulty}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// ============================================
// ACTIVITY SCREEN (LIVE DATA)
// ============================================
const ActivityScreen = () => {
  const { token, user, profile } = useAuth();
  const [todayStats, setTodayStats] = useState(null);
  const [weeklyStats, setWeeklyStats] = useState([]);
  const [heartRate, setHeartRate] = useState([]);
  const [activities, setActivities] = useState([]);
  const [selectedMetric, setSelectedMetric] = useState("steps");
  const [loading, setLoading] = useState(true);
  const [logModalOpen, setLogModalOpen] = useState(false);

  useEffect(() => { loadActivity(); }, []);

  const loadActivity = async () => {
    setLoading(true);
    try {
      const today = new Date().toISOString().split("T")[0];
      const [stats, weekly, hr, acts] = await Promise.all([
        supabase.query("daily_stats", token, { filters: `user_id=eq.${user.id}&date=eq.${today}`, limit: "1" }),
        supabase.query("daily_stats", token, { filters: `user_id=eq.${user.id}`, order: "date.desc", limit: "7" }),
        supabase.query("heart_rate_readings", token, { filters: `user_id=eq.${user.id}`, order: "recorded_at.desc", limit: "48" }),
        supabase.query("activities", token, { filters: `user_id=eq.${user.id}`, order: "started_at.desc", limit: "20" }),
      ]);
      setTodayStats(stats[0] || null);
      setWeeklyStats(weekly.reverse().map(d => ({ day: new Date(d.date).toLocaleDateString("en",{weekday:"short"}), steps: d.total_steps, cal: Math.round(Number(d.total_calories)), mins: d.active_minutes, dist: (Number(d.total_distance_meters)/1000).toFixed(1) })));
      setHeartRate(hr.reverse().map(r => ({ time: new Date(r.recorded_at).toLocaleTimeString("en",{hour:"2-digit",minute:"2-digit"}), bpm: r.bpm })));
      setActivities(acts);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  // Log new activity
  const [newAct, setNewAct] = useState({ activity_type: "run", title: "", duration_seconds: 1800, distance_meters: 5000, calories_burned: 300 });
  const saveActivity = async () => {
    try {
      await supabase.insert("activities", { ...newAct, user_id: user.id, started_at: new Date().toISOString(), is_public: true }, token);
      setLogModalOpen(false);
      loadActivity();
    } catch (e) { console.error(e); }
  };

  if (loading) return <Loading text="Loading activity data..." />;

  const ts = todayStats || {};
  const stepGoal = profile?.daily_step_goal || 10000;
  const calGoal = profile?.daily_calorie_goal || 500;
  const minGoal = profile?.daily_active_minutes_goal || 30;
  const overallPct = Math.round(((Number(ts.move_ring_progress||0) + Number(ts.exercise_ring_progress||0) + Number(ts.stand_ring_progress||0)) / 3) * 100);

  return (
    <div style={{ padding: "0 16px 100px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "16px 0 20px" }}>
        <div>
          <div style={{ fontSize: 26, fontWeight: 700, color: C.text }}>Activity</div>
          <div style={{ fontSize: 14, color: C.text2 }}>Track your daily progress</div>
        </div>
        <button onClick={() => setLogModalOpen(true)} style={{ width: 40, height: 40, borderRadius: 20, background: C.pri, border: "none", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
          <Plus size={20} color="#fff" /></button>
      </div>

      {/* Rings */}
      <div style={{ background: C.bgCard, borderRadius: 20, padding: 24, marginBottom: 20, border: `1px solid ${C.bor}`, textAlign: "center" }}>
        <div style={{ display: "flex", justifyContent: "center", marginBottom: 20, position: "relative" }}>
          <ActivityRings move={Number(ts.move_ring_progress||0)} exercise={Number(ts.exercise_ring_progress||0)} stand={Number(ts.stand_ring_progress||0)} size={180} sw={14} />
          <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", textAlign: "center" }}>
            <div style={{ fontSize: 28, fontWeight: 700, color: C.text }}>{overallPct}%</div>
            <div style={{ fontSize: 11, color: C.text2 }}>Complete</div>
          </div>
        </div>
        <div style={{ display: "flex", justifyContent: "center", gap: 32 }}>
          {[{ l: "Move", v: `${Math.round(Number(ts.total_calories||0))}/${calGoal}`, c: C.rMove },
            { l: "Exercise", v: `${ts.active_minutes||0}/${minGoal}`, c: C.rExer },
            { l: "Steps", v: `${((ts.total_steps||0)/1000).toFixed(1)}K/${stepGoal/1000}K`, c: C.rStand }
          ].map(r => (
            <div key={r.l} style={{ textAlign: "center" }}>
              <div style={{ width: 10, height: 10, borderRadius: 5, background: r.c, margin: "0 auto 6px" }} />
              <div style={{ fontSize: 15, fontWeight: 600, color: C.text }}>{r.v}</div>
              <div style={{ fontSize: 11, color: C.text2 }}>{r.l}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Metric Tabs */}
      <div style={{ display: "flex", gap: 8, marginBottom: 16, overflowX: "auto" }}>
        {[{ k: "steps", l: "Steps", i: Footprints }, { k: "calories", l: "Calories", i: Flame }, { k: "heartrate", l: "Heart Rate", i: Heart }, { k: "distance", l: "Distance", i: Route }].map(({ k,l,i:Icon }) => (
          <button key={k} onClick={() => setSelectedMetric(k)} style={{ display: "flex", alignItems: "center", gap: 6, padding: "8px 14px", borderRadius: 20,
            border: `1px solid ${selectedMetric===k?C.pri:C.bor}`, background: selectedMetric===k?`${C.pri}15`:"transparent",
            color: selectedMetric===k?C.pri:C.text2, fontSize: 13, fontWeight: 500, cursor: "pointer", whiteSpace: "nowrap" }}>
            <Icon size={14} /> {l}
          </button>
        ))}
      </div>

      {/* Chart */}
      <div style={{ background: C.bgCard, borderRadius: 20, padding: 20, marginBottom: 20, border: `1px solid ${C.bor}` }}>
        {selectedMetric === "steps" && weeklyStats.length > 0 && (<>
          <div style={{ fontSize: 24, fontWeight: 700, color: C.text }}>{(ts.total_steps||0).toLocaleString()}</div>
          <div style={{ fontSize: 13, color: C.text2, marginBottom: 16 }}>steps today</div>
          <ResponsiveContainer width="100%" height={180}><BarChart data={weeklyStats}><XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: C.text3, fontSize: 11 }}/><YAxis hide/><Tooltip contentStyle={{ background: C.bgEl, border: `1px solid ${C.bor}`, borderRadius: 12, fontSize: 12 }} cursor={{ fill: "transparent" }}/><Bar dataKey="steps" fill={C.pri} radius={[6,6,0,0]} /></BarChart></ResponsiveContainer>
        </>)}
        {selectedMetric === "calories" && weeklyStats.length > 0 && (<>
          <div style={{ fontSize: 24, fontWeight: 700, color: C.text }}>{Math.round(Number(ts.total_calories||0))}</div>
          <div style={{ fontSize: 13, color: C.text2, marginBottom: 16 }}>kcal burned today</div>
          <ResponsiveContainer width="100%" height={180}><AreaChart data={weeklyStats}><defs><linearGradient id="cg" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor={C.danger} stopOpacity={0.3}/><stop offset="100%" stopColor={C.danger} stopOpacity={0}/></linearGradient></defs><XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: C.text3, fontSize: 11 }}/><YAxis hide/><Tooltip contentStyle={{ background: C.bgEl, border: `1px solid ${C.bor}`, borderRadius: 12, fontSize: 12 }}/><Area type="monotone" dataKey="cal" stroke={C.danger} strokeWidth={2} fill="url(#cg)" /></AreaChart></ResponsiveContainer>
        </>)}
        {selectedMetric === "heartrate" && heartRate.length > 0 && (<>
          <div style={{ fontSize: 24, fontWeight: 700, color: C.text }}>{ts.avg_heart_rate||"--"} <span style={{ fontSize: 14, color: C.text2 }}>bpm avg</span></div>
          <div style={{ fontSize: 13, color: C.text2, marginBottom: 16 }}>Resting: {ts.resting_heart_rate||"--"} bpm</div>
          <ResponsiveContainer width="100%" height={180}><AreaChart data={heartRate}><defs><linearGradient id="hg" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#FF2D55" stopOpacity={0.3}/><stop offset="100%" stopColor="#FF2D55" stopOpacity={0}/></linearGradient></defs><XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fill: C.text3, fontSize: 10 }} interval={11}/><YAxis hide domain={[50,170]}/><Tooltip contentStyle={{ background: C.bgEl, border: `1px solid ${C.bor}`, borderRadius: 12, fontSize: 12 }}/><Area type="monotone" dataKey="bpm" stroke="#FF2D55" strokeWidth={2} fill="url(#hg)" /></AreaChart></ResponsiveContainer>
        </>)}
        {selectedMetric === "distance" && weeklyStats.length > 0 && (<>
          <div style={{ fontSize: 24, fontWeight: 700, color: C.text }}>{(Number(ts.total_distance_meters||0)/1000).toFixed(1)} km</div>
          <div style={{ fontSize: 13, color: C.text2, marginBottom: 16 }}>distance today</div>
          <ResponsiveContainer width="100%" height={180}><BarChart data={weeklyStats}><XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: C.text3, fontSize: 11 }}/><YAxis hide/><Tooltip contentStyle={{ background: C.bgEl, border: `1px solid ${C.bor}`, borderRadius: 12, fontSize: 12 }}/><Bar dataKey="dist" fill={C.accB} radius={[6,6,0,0]} /></BarChart></ResponsiveContainer>
        </>)}
        {(weeklyStats.length === 0 && heartRate.length === 0) && <EmptyState icon={BarChart3} title="No data yet" subtitle="Track activities to see charts" />}
      </div>

      {/* All Activities */}
      <div style={{ fontSize: 17, fontWeight: 600, color: C.text, marginBottom: 14 }}>All Activities ({activities.length})</div>
      {activities.length === 0 ? <EmptyState icon={Activity} title="No activities yet" subtitle="Tap + to log your first activity" action="Log Activity" onAction={() => setLogModalOpen(true)} /> : (
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {activities.map(act => {
            const Icon = getActivityIcon(act.activity_type); const color = getActivityColor(act.activity_type);
            return (
              <div key={act.id} style={{ background: C.bgCard, borderRadius: 16, padding: 16, border: `1px solid ${C.bor}` }}>
                <div style={{ display: "flex", alignItems: "center", gap: 14, marginBottom: 12 }}>
                  <div style={{ width: 44, height: 44, borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", background: `${color}15` }}>
                    <Icon size={20} color={color} /></div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 15, fontWeight: 600, color: C.text }}>{act.title || act.activity_type}</div>
                    <div style={{ fontSize: 12, color: C.text2 }}>{timeAgo(act.started_at)}</div>
                  </div>
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr", gap: 8 }}>
                  {[{ l: "Distance", v: Number(act.distance_meters)>0?`${(Number(act.distance_meters)/1000).toFixed(1)} km`:"—" },
                    { l: "Duration", v: formatDuration(act.duration_seconds||0) },
                    { l: "Calories", v: `${Math.round(Number(act.calories_burned||0))}` },
                    { l: "Avg HR", v: act.avg_heart_rate ? `${act.avg_heart_rate}` : "—" }
                  ].map(s => (<div key={s.l} style={{ textAlign: "center" }}><div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{s.v}</div><div style={{ fontSize: 10, color: C.text3 }}>{s.l}</div></div>))}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Log Activity Modal */}
      {logModalOpen && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.7)", zIndex: 200, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <div style={{ width: "100%", maxWidth: 430, background: C.bgCard, borderRadius: "24px 24px 0 0", padding: 24, border: `1px solid ${C.bor}` }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
              <div style={{ fontSize: 20, fontWeight: 700, color: C.text }}>Log Activity</div>
              <button onClick={() => setLogModalOpen(false)} style={{ background: "none", border: "none", cursor: "pointer" }}><X size={20} color={C.text2} /></button>
            </div>
            <div style={{ marginBottom: 14 }}>
              <label style={{ fontSize: 13, color: C.text2, display: "block", marginBottom: 6 }}>Type</label>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {["run","walk","cycle","swim","hike","yoga"].map(t => (
                  <button key={t} onClick={() => setNewAct({...newAct, activity_type: t})} style={{ padding: "8px 14px", borderRadius: 10, border: `1px solid ${newAct.activity_type===t?C.pri:C.bor}`, background: newAct.activity_type===t?`${C.pri}15`:"transparent", color: newAct.activity_type===t?C.pri:C.text2, fontSize: 13, cursor: "pointer", textTransform: "capitalize" }}>{t}</button>
                ))}
              </div>
            </div>
            {[{ k: "title", l: "Title", t: "text", p: "Morning Run" }, { k: "duration_seconds", l: "Duration (seconds)", t: "number", p: "1800" }, { k: "distance_meters", l: "Distance (meters)", t: "number", p: "5000" }, { k: "calories_burned", l: "Calories", t: "number", p: "300" }].map(f => (
              <div key={f.k} style={{ marginBottom: 14 }}>
                <label style={{ fontSize: 13, color: C.text2, display: "block", marginBottom: 6 }}>{f.l}</label>
                <input type={f.t} value={newAct[f.k]||""} onChange={e => setNewAct({...newAct, [f.k]: f.t==="number"?Number(e.target.value):e.target.value})} placeholder={f.p}
                  style={{ width: "100%", background: C.bgInput, border: `1px solid ${C.bor}`, borderRadius: 12, padding: "12px 14px", color: C.text, fontSize: 15, outline: "none", boxSizing: "border-box" }} />
              </div>
            ))}
            <button onClick={saveActivity} style={{ width: "100%", padding: 14, borderRadius: 14, border: "none", background: `linear-gradient(135deg, ${C.pri}, ${C.priL})`, color: "#fff", fontSize: 16, fontWeight: 700, cursor: "pointer", marginTop: 8 }}>Save Activity</button>
          </div>
        </div>
      )}
    </div>
  );
};

// ============================================
// WORKOUT SCREEN (LIVE DATA)
// ============================================
const WorkoutScreen = () => {
  const { token, user } = useAuth();
  const [plans, setPlans] = useState([]);
  const [sessions, setSessions] = useState([]);
  const [exercises, setExercises] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [activeWorkout, setActiveWorkout] = useState(null);
  const [timer, setTimer] = useState(0);
  const [isRunning, setIsRunning] = useState(false);
  const [completedExercises, setCompletedExercises] = useState(new Set());
  const [loading, setLoading] = useState(true);
  const intervalRef = useRef(null);

  useEffect(() => { loadWorkouts(); }, []);

  useEffect(() => {
    if (isRunning) intervalRef.current = setInterval(() => setTimer(t => t+1), 1000);
    else clearInterval(intervalRef.current);
    return () => clearInterval(intervalRef.current);
  }, [isRunning]);

  const loadWorkouts = async () => {
    setLoading(true);
    try {
      const [p, s] = await Promise.all([
        supabase.query("workout_plans", token, { filters: "or=(is_featured.eq.true,is_public.eq.true)", order: "created_at.desc" }),
        supabase.query("workout_sessions", token, { filters: `user_id=eq.${user.id}`, order: "started_at.desc", limit: "10" }),
      ]);
      setPlans(p); setSessions(s);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const startWorkout = async (plan) => {
    try {
      const exs = await supabase.query("workout_exercises", token, { filters: `plan_id=eq.${plan.id}`, order: "sort_order.asc" });
      setExercises(exs);
      setActiveWorkout(plan);
      setTimer(0); setIsRunning(false); setCompletedExercises(new Set());
    } catch (e) { console.error(e); }
  };

  const finishWorkout = async (feeling) => {
    try {
      setIsRunning(false);
      await supabase.insert("workout_sessions", {
        user_id: user.id, plan_id: activeWorkout.id, title: activeWorkout.title,
        started_at: new Date(Date.now() - timer*1000).toISOString(), ended_at: new Date().toISOString(),
        duration_seconds: timer, calories_burned: Math.round(timer * 0.15), feeling,
      }, token);
      // Update profile workouts count
      await supabase.update("profiles", { total_workouts: (sessions.length||0)+1 }, `id=eq.${user.id}`, token);
      setActiveWorkout(null); setTimer(0);
      loadWorkouts();
    } catch (e) { console.error(e); }
  };

  const toggleExercise = (exId) => {
    const s = new Set(completedExercises);
    s.has(exId) ? s.delete(exId) : s.add(exId);
    setCompletedExercises(s);
  };

  const fmtTimer = (s) => `${String(Math.floor(s/60)).padStart(2,"0")}:${String(s%60).padStart(2,"0")}`;
  const categories = ["all", "strength", "cardio", "hiit", "flexibility"];
  const filtered = selectedCategory === "all" ? plans : plans.filter(p => p.category === selectedCategory);
  const categoryEmoji = { strength: "💪", hiit: "🔥", flexibility: "🧘", cardio: "🏃", custom: "⚡" };
  const feelingMap = { amazing: "🔥", good: "💪", okay: "😊", tough: "😤", exhausted: "😵" };

  if (loading) return <Loading text="Loading workouts..." />;

  // Active workout view
  if (activeWorkout) return (
    <div style={{ padding: "0 16px 100px" }}>
      <div style={{ padding: "16px 0 20px", display: "flex", alignItems: "center", gap: 12 }}>
        <button onClick={() => { setActiveWorkout(null); setIsRunning(false); }} style={{ width: 36, height: 36, borderRadius: 18, background: C.bgCard, border: `1px solid ${C.bor}`, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
          <ChevronLeft size={18} color={C.text} /></button>
        <div><div style={{ fontSize: 20, fontWeight: 700, color: C.text }}>{activeWorkout.title}</div>
          <div style={{ fontSize: 13, color: C.text2 }}>{activeWorkout.category} · {activeWorkout.difficulty}</div></div>
      </div>
      <div style={{ background: C.bgCard, borderRadius: 20, padding: 32, marginBottom: 20, border: `1px solid ${C.bor}`, textAlign: "center" }}>
        <div style={{ fontSize: 56, fontWeight: 700, color: C.text, fontFamily: "monospace", letterSpacing: 4 }}>{fmtTimer(timer)}</div>
        <div style={{ fontSize: 13, color: C.text2, marginBottom: 24 }}>Workout Duration</div>
        <div style={{ display: "flex", justifyContent: "center", gap: 16 }}>
          <button onClick={() => setIsRunning(!isRunning)} style={{ width: 64, height: 64, borderRadius: 32, border: "none", cursor: "pointer", background: isRunning ? C.danger : C.pri, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 4px 20px ${isRunning?C.danger:C.pri}40` }}>
            {isRunning ? <Pause size={24} color="#fff" /> : <Play size={24} color="#fff" style={{ marginLeft: 2 }} />}</button>
          {timer > 0 && <button onClick={() => finishWorkout("good")} style={{ width: 64, height: 64, borderRadius: 32, border: `2px solid ${C.acc}`, background: "transparent", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Check size={24} color={C.acc} /></button>}
        </div>
        <div style={{ display: "flex", justifyContent: "center", gap: 32, marginTop: 24 }}>
          <div style={{ textAlign: "center" }}><div style={{ fontSize: 20, fontWeight: 700, color: C.text }}>{Math.round(timer*0.15)}</div><div style={{ fontSize: 11, color: C.text2 }}>Calories</div></div>
          <div style={{ textAlign: "center" }}><div style={{ fontSize: 20, fontWeight: 700, color: C.text }}>{completedExercises.size}/{exercises.length}</div><div style={{ fontSize: 11, color: C.text2 }}>Exercises</div></div>
        </div>
      </div>
      <div style={{ fontSize: 17, fontWeight: 600, color: C.text, marginBottom: 14 }}>Exercises</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {exercises.map((ex, i) => {
          const done = completedExercises.has(ex.id);
          return (
            <div key={ex.id} onClick={() => toggleExercise(ex.id)} style={{ background: C.bgCard, borderRadius: 14, padding: "14px 16px", border: `1px solid ${done?C.acc+"40":C.bor}`, display: "flex", alignItems: "center", gap: 14, opacity: done?0.6:1, cursor: "pointer" }}>
              <div style={{ width: 32, height: 32, borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center", background: done?`${C.acc}20`:`${C.pri}15`, border: `2px solid ${done?C.acc:C.bor}` }}>
                {done ? <Check size={14} color={C.acc}/> : <span style={{ fontSize: 12, fontWeight: 600, color: C.text2 }}>{i+1}</span>}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: C.text, textDecoration: done?"line-through":"none" }}>{ex.exercise_name}</div>
                <div style={{ fontSize: 12, color: C.text2 }}>
                  {ex.sets && ex.reps ? `${ex.sets} × ${ex.reps}` : ex.sets && ex.duration_seconds ? `${ex.sets} × ${ex.duration_seconds}s` : ""}
                  {ex.weight_kg ? ` · ${ex.weight_kg}kg` : ""} · Rest {ex.rest_seconds}s
                </div>
              </div>
            </div>
          );
        })}
      </div>
      {/* Feeling selector when finishing */}
      {timer > 10 && (
        <div style={{ marginTop: 20 }}>
          <div style={{ fontSize: 15, fontWeight: 600, color: C.text, marginBottom: 10 }}>How was it?</div>
          <div style={{ display: "flex", gap: 10 }}>
            {Object.entries(feelingMap).map(([k,v]) => (
              <button key={k} onClick={() => finishWorkout(k)} style={{ flex: 1, padding: "12px 0", borderRadius: 12, border: `1px solid ${C.bor}`, background: C.bgCard, cursor: "pointer", textAlign: "center" }}>
                <div style={{ fontSize: 24 }}>{v}</div><div style={{ fontSize: 11, color: C.text2, textTransform: "capitalize", marginTop: 4 }}>{k}</div>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );

  // Plans list view
  return (
    <div style={{ padding: "0 16px 100px" }}>
      <div style={{ padding: "16px 0 20px" }}>
        <div style={{ fontSize: 26, fontWeight: 700, color: C.text }}>Workouts</div>
        <div style={{ fontSize: 14, color: C.text2 }}>Plans, sessions & exercises</div>
      </div>

      {/* Quick Start */}
      <div style={{ background: `linear-gradient(135deg, ${C.pri}, ${C.priL})`, borderRadius: 20, padding: 24, marginBottom: 20, cursor: "pointer", boxShadow: `0 8px 32px ${C.pri}30` }}
        onClick={() => startWorkout(plans[0] || { id: null, title: "Quick Workout", category: "custom", difficulty: "intermediate" })}>
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{ width: 56, height: 56, borderRadius: 28, background: "rgba(255,255,255,0.2)", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Play size={28} color="#fff" style={{ marginLeft: 3 }} /></div>
          <div><div style={{ fontSize: 20, fontWeight: 700, color: "#fff" }}>Quick Start</div>
            <div style={{ fontSize: 13, color: "rgba(255,255,255,0.8)" }}>Start a workout & track as you go</div></div>
        </div>
      </div>

      {/* Categories */}
      <div style={{ display: "flex", gap: 8, marginBottom: 20, overflowX: "auto" }}>
        {categories.map(c => (
          <button key={c} onClick={() => setSelectedCategory(c)} style={{ padding: "8px 16px", borderRadius: 20, border: `1px solid ${selectedCategory===c?C.pri:C.bor}`, background: selectedCategory===c?`${C.pri}15`:"transparent", color: selectedCategory===c?C.pri:C.text2, fontSize: 13, fontWeight: 500, cursor: "pointer", textTransform: "capitalize", whiteSpace: "nowrap" }}>{c}</button>
        ))}
      </div>

      {/* Plans */}
      <div style={{ fontSize: 17, fontWeight: 600, color: C.text, marginBottom: 14 }}>Featured Plans ({filtered.length})</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {filtered.map(p => (
          <div key={p.id} onClick={() => startWorkout(p)} style={{ background: C.bgCard, borderRadius: 16, padding: 18, border: `1px solid ${C.bor}`, cursor: "pointer", display: "flex", alignItems: "center", gap: 16 }}>
            <div style={{ width: 56, height: 56, borderRadius: 14, display: "flex", alignItems: "center", justifyContent: "center", background: `${C.pri}15`, fontSize: 28, flexShrink: 0 }}>{categoryEmoji[p.category]||"💪"}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 16, fontWeight: 600, color: C.text, marginBottom: 4 }}>{p.title}</div>
              <div style={{ fontSize: 12, color: C.text2 }}>{p.estimated_duration_minutes} min · {p.difficulty}</div>
              {p.description && <div style={{ fontSize: 12, color: C.text3, marginTop: 4 }}>{p.description.slice(0,80)}...</div>}
            </div>
            <ChevronRight size={18} color={C.text3} />
          </div>
        ))}
      </div>

      {/* Recent Sessions */}
      {sessions.length > 0 && (<>
        <div style={{ fontSize: 17, fontWeight: 600, color: C.text, margin: "24px 0 14px" }}>Recent Sessions ({sessions.length})</div>
        {sessions.map(s => (
          <div key={s.id} style={{ background: C.bgCard, borderRadius: 14, padding: "14px 16px", marginBottom: 8, border: `1px solid ${C.bor}`, display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 40, height: 40, borderRadius: 10, background: `${C.pri}15`, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Dumbbell size={18} color={C.pri} /></div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{s.title}</div>
              <div style={{ fontSize: 12, color: C.text2 }}>{timeAgo(s.started_at)} · {formatDuration(s.duration_seconds||0)} · {Math.round(Number(s.calories_burned||0))} cal</div>
            </div>
            <div style={{ fontSize: 18 }}>{feelingMap[s.feeling] || ""}</div>
          </div>
        ))}
      </>)}
    </div>
  );
};

// ============================================
// LEADERBOARD SCREEN (LIVE DATA)
// ============================================
const LeaderboardScreen = () => {
  const { token, user, profile } = useAuth();
  const [entries, setEntries] = useState([]);
  const [allProfiles, setAllProfiles] = useState([]);
  const [period, setPeriod] = useState("weekly");
  const [metric, setMetric] = useState("steps");
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadLeaderboard(); }, [period]);

  const loadLeaderboard = async () => {
    setLoading(true);
    try {
      const [e, p] = await Promise.all([
        supabase.query("leaderboard_entries", token, { filters: `period_type=eq.${period}`, order: "rank.asc", limit: "20" }),
        supabase.query("profiles", token, { select: "id,full_name,username,avatar_url,current_streak,total_workouts" }),
      ]);
      setEntries(e); setAllProfiles(p);
    } catch (err) { console.error(err); }
    setLoading(false);
  };

  // Build combined leaderboard from entries + profiles
  const leaderboard = useMemo(() => {
    if (entries.length === 0) {
      // Fallback: build from profiles
      return allProfiles.sort((a,b) => (b.total_workouts||0)-(a.total_workouts||0)).map((p, i) => ({
        rank: i+1, name: p.full_name || p.username || "User", isUser: p.id === user.id,
        steps: 0, workouts: p.total_workouts || 0, streak: p.current_streak || 0,
      }));
    }
    return entries.map(e => {
      const p = allProfiles.find(x => x.id === e.user_id);
      return { rank: e.rank, name: p?.full_name || "User", isUser: e.user_id === user.id,
        steps: e.total_steps, workouts: e.total_workouts, streak: p?.current_streak || 0 };
    });
  }, [entries, allProfiles, user.id]);

  const userRank = leaderboard.find(l => l.isUser)?.rank || "—";
  const metricVal = (l) => metric==="steps"?l.steps?.toLocaleString():metric==="workouts"?l.workouts:`${l.streak}d`;
  const podiumColors = ["#C0C0C0", "#FFD700", "#CD7F32"];

  if (loading) return <Loading text="Loading leaderboard..." />;

  return (
    <div style={{ padding: "0 16px 100px" }}>
      <div style={{ padding: "16px 0 20px" }}>
        <div style={{ fontSize: 26, fontWeight: 700, color: C.text }}>Leaderboard</div>
        <div style={{ fontSize: 14, color: C.text2 }}>Compete with the community</div>
      </div>
      <div style={{ display: "flex", background: C.bgCard, borderRadius: 12, padding: 4, marginBottom: 16, border: `1px solid ${C.bor}` }}>
        {["weekly","monthly","all_time"].map(p => (
          <button key={p} onClick={() => setPeriod(p)} style={{ flex: 1, padding: "8px 0", borderRadius: 8, border: "none", cursor: "pointer", fontSize: 13, fontWeight: 600, textTransform: "capitalize", background: period===p?C.pri:"transparent", color: period===p?"#fff":C.text2 }}>{p.replace("_"," ")}</button>
        ))}
      </div>
      <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
        {[{k:"steps",l:"Steps"},{k:"workouts",l:"Workouts"},{k:"streak",l:"Streak"}].map(m => (
          <button key={m.k} onClick={() => setMetric(m.k)} style={{ padding: "6px 14px", borderRadius: 16, border: `1px solid ${metric===m.k?C.pri:C.bor}`, background: metric===m.k?`${C.pri}15`:"transparent", color: metric===m.k?C.pri:C.text2, fontSize: 13, fontWeight: 500, cursor: "pointer" }}>{m.l}</button>
        ))}
      </div>

      {leaderboard.length === 0 ? <EmptyState icon={Trophy} title="No leaderboard data yet" subtitle="Complete activities to appear on the leaderboard" /> : (<>
        {/* Top 3 podium */}
        {leaderboard.length >= 3 && (
          <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "center", gap: 12, marginBottom: 24, padding: "0 12px" }}>
            {[leaderboard[1], leaderboard[0], leaderboard[2]].map((u, i) => {
              const heights = [120,150,100]; const sizes = [52,64,48];
              return (<div key={i} style={{ textAlign: "center", flex: 1 }}>
                <div style={{ width: sizes[i], height: sizes[i], borderRadius: sizes[i]/2, margin: "0 auto 8px", background: u?.isUser?`${C.pri}20`:C.bgCard, border: `3px solid ${podiumColors[i]}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: sizes[i]>50?20:16, fontWeight: 700, color: C.text, boxShadow: `0 0 20px ${podiumColors[i]}30` }}>
                  {u?.name?.charAt(0) || "?"}</div>
                <div style={{ fontSize: 13, fontWeight: 600, color: u?.isUser?C.pri:C.text, marginBottom: 2 }}>{u?.name||"?"}</div>
                <div style={{ fontSize: 12, color: C.text2, marginBottom: 8 }}>{u?metricVal(u):"—"}</div>
                <div style={{ height: heights[i], borderRadius: "12px 12px 0 0", background: `linear-gradient(to top, ${podiumColors[i]}20, ${podiumColors[i]}40)`, display: "flex", alignItems: "flex-start", justifyContent: "center", paddingTop: 12 }}>
                  <span style={{ fontSize: 20, fontWeight: 700, color: podiumColors[i] }}>#{u?.rank||"?"}</span></div>
              </div>);
            })}
          </div>
        )}

        {/* Rest of leaderboard */}
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          {leaderboard.slice(3).map(u => (
            <div key={u.rank} style={{ background: u.isUser?`${C.pri}08`:C.bgCard, borderRadius: 14, padding: "12px 16px", border: `1px solid ${u.isUser?C.pri+"40":C.bor}`, display: "flex", alignItems: "center", gap: 14 }}>
              <div style={{ width: 28, fontSize: 14, fontWeight: 700, color: C.text2, textAlign: "center" }}>{u.rank}</div>
              <div style={{ width: 40, height: 40, borderRadius: 20, background: C.bgEl, display: "flex", alignItems: "center", justifyContent: "center", border: `2px solid ${C.bor}`, fontSize: 16, fontWeight: 600, color: C.text2 }}>{u.name.charAt(0)}</div>
              <div style={{ flex: 1 }}><div style={{ fontSize: 14, fontWeight: 600, color: u.isUser?C.pri:C.text }}>{u.name}{u.isUser&&<span style={{ fontSize: 11, color: C.text2 }}> (You)</span>}</div>
                <div style={{ fontSize: 12, color: C.text2 }}>{metricVal(u)}</div></div>
            </div>
          ))}
        </div>

        <div style={{ background: `linear-gradient(135deg, ${C.pri}15, ${C.priL}10)`, borderRadius: 16, padding: 20, marginTop: 20, border: `1px solid ${C.pri}30`, textAlign: "center" }}>
          <div style={{ fontSize: 14, color: C.text2, marginBottom: 4 }}>Your Ranking</div>
          <div style={{ fontSize: 36, fontWeight: 700, color: C.pri }}>#{userRank}</div>
        </div>
      </>)}
    </div>
  );
};

// ============================================
// PROFILE SCREEN (LIVE DATA)
// ============================================
// ============================================
// CONNECTED APPS COMPONENT
// ============================================
const EDGE_FN_URL = `${SUPABASE_URL}/functions/v1/fitness-oauth`;

const ConnectedApps = ({ userId, token }) => {
  const [connectedAccounts, setConnectedAccounts] = useState([]);
  const [syncing, setSyncing] = useState({});
  const [loading, setLoading] = useState(true);

  const providers = [
    { id: "strava", name: "Strava", icon: "🏃", color: "#FC4C02", desc: "Running, cycling, swimming with GPS routes and heart rate" },
    { id: "google_fit", name: "Google Fit", icon: "💚", color: "#4285F4", desc: "Steps, heart rate, calories from Android & Wear OS" },
    { id: "fitbit", name: "Fitbit", icon: "💙", color: "#00B0B9", desc: "Steps, sleep, heart rate from Fitbit devices" },
    { id: "apple_health", name: "Apple Health", icon: "❤️", color: "#FF2D55", desc: "Coming soon — via Terra health data bridge" },
  ];

  useEffect(() => {
    loadConnections();
    // Check URL for newly connected provider
    const params = new URLSearchParams(window.location.search);
    const connected = params.get("connected");
    if (connected) {
      window.history.replaceState(null, "", window.location.pathname);
      loadConnections();
    }
  }, []);

  const loadConnections = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${EDGE_FN_URL}/status?user_id=${userId}`);
      const data = await res.json();
      setConnectedAccounts(Array.isArray(data) ? data : []);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const connectProvider = (providerId) => {
    const authUrl = `${EDGE_FN_URL}/${providerId.replace("_", "-")}/auth?user_id=${userId}`;
    window.location.href = authUrl;
  };

  const syncProvider = async (providerId) => {
    setSyncing(s => ({ ...s, [providerId]: true }));
    try {
      const res = await fetch(`${EDGE_FN_URL}/${providerId.replace("_", "-")}/sync?user_id=${userId}`);
      const data = await res.json();
      await loadConnections();
    } catch (e) { console.error(e); }
    setSyncing(s => ({ ...s, [providerId]: false }));
  };

  const syncAll = async () => {
    setSyncing({ all: true });
    try {
      await fetch(`${EDGE_FN_URL}/sync-all?user_id=${userId}`);
      await loadConnections();
    } catch (e) { console.error(e); }
    setSyncing({});
  };

  const isConnected = (providerId) => connectedAccounts.some(a => a.provider === providerId);
  const getAccount = (providerId) => connectedAccounts.find(a => a.provider === providerId);

  if (loading) return <Loading text="Loading connections..." />;

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
        <div>
          <div style={{ fontSize: 15, fontWeight: 600, color: C.text }}>Connected Apps</div>
          <div style={{ fontSize: 12, color: C.text2 }}>{connectedAccounts.length} connected</div>
        </div>
        {connectedAccounts.length > 0 && (
          <button onClick={syncAll} disabled={syncing.all} style={{ padding: "8px 16px", borderRadius: 10, border: `1px solid ${C.pri}30`, background: `${C.pri}10`, color: C.pri, fontSize: 13, fontWeight: 600, cursor: "pointer", display: "flex", alignItems: "center", gap: 6 }}>
            <RefreshCw size={14} style={syncing.all ? { animation: "spin 1s linear infinite" } : {}} /> Sync All
          </button>
        )}
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {providers.map(p => {
          const connected = isConnected(p.id);
          const account = getAccount(p.id);
          const isApple = p.id === "apple_health";
          return (
            <div key={p.id} style={{ background: C.bgCard, borderRadius: 16, padding: 18, border: `1px solid ${connected ? p.color + "30" : C.bor}` }}>
              <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                <div style={{ width: 48, height: 48, borderRadius: 14, display: "flex", alignItems: "center", justifyContent: "center", background: `${p.color}15`, fontSize: 24, flexShrink: 0 }}>
                  {p.icon}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span style={{ fontSize: 16, fontWeight: 600, color: C.text }}>{p.name}</span>
                    {connected && <span style={{ fontSize: 10, fontWeight: 600, color: C.acc, background: `${C.acc}15`, padding: "2px 8px", borderRadius: 6 }}>Connected</span>}
                  </div>
                  <div style={{ fontSize: 12, color: C.text2, marginTop: 2 }}>{p.desc}</div>
                  {connected && account?.last_sync_at && (
                    <div style={{ fontSize: 11, color: C.text3, marginTop: 4 }}>Last synced: {timeAgo(account.last_sync_at)}</div>
                  )}
                </div>
                {isApple ? (
                  <div style={{ padding: "8px 14px", borderRadius: 10, background: C.bgEl, color: C.text3, fontSize: 12, fontWeight: 500 }}>Soon</div>
                ) : connected ? (
                  <button onClick={() => syncProvider(p.id)} disabled={syncing[p.id]} style={{ padding: "8px 14px", borderRadius: 10, border: `1px solid ${C.bor}`, background: "transparent", color: C.text, fontSize: 13, fontWeight: 500, cursor: "pointer", display: "flex", alignItems: "center", gap: 6 }}>
                    <RefreshCw size={13} style={syncing[p.id] ? { animation: "spin 1s linear infinite" } : {}} /> Sync
                  </button>
                ) : (
                  <button onClick={() => connectProvider(p.id)} style={{ padding: "8px 16px", borderRadius: 10, border: "none", background: p.color, color: "#fff", fontSize: 13, fontWeight: 600, cursor: "pointer" }}>Connect</button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ background: `${C.accB}08`, borderRadius: 14, padding: 16, marginTop: 16, border: `1px solid ${C.accB}20` }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: C.text, marginBottom: 4 }}>How it works</div>
        <div style={{ fontSize: 12, color: C.text2, lineHeight: 1.5 }}>
          Connect your fitness apps to automatically import activities, steps, heart rate, and calories into STRIDE. Data syncs on demand when you tap Sync, and all your data stays private in your account.
        </div>
      </div>
    </div>
  );
};

const ProfileScreen = ({ onLogout }) => {
  const { token, user, profile, refreshProfile } = useAuth();
  const [achievementsData, setAchievementsData] = useState([]);
  const [userAchievements, setUserAchievements] = useState([]);
  const [stats, setStats] = useState([]);
  const [activeTab, setActiveTab] = useState("achievements");
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [editForm, setEditForm] = useState({});

  useEffect(() => { loadProfile(); }, []);

  const loadProfile = async () => {
    setLoading(true);
    try {
      const [achs, userAchs, allStats] = await Promise.all([
        supabase.query("achievements", token, { order: "created_at.asc" }),
        supabase.query("user_achievements", token, { filters: `user_id=eq.${user.id}` }),
        supabase.query("daily_stats", token, { filters: `user_id=eq.${user.id}`, order: "date.desc", limit: "90" }),
      ]);
      setAchievementsData(achs);
      setUserAchievements(userAchs.map(a => a.achievement_id));
      setStats(allStats);
      setEditForm({ full_name: profile?.full_name||"", bio: profile?.bio||"", daily_step_goal: profile?.daily_step_goal||10000, daily_calorie_goal: profile?.daily_calorie_goal||500, daily_active_minutes_goal: profile?.daily_active_minutes_goal||30 });
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const saveProfile = async () => {
    try {
      await supabase.update("profiles", editForm, `id=eq.${user.id}`, token);
      await refreshProfile();
      setEditing(false);
    } catch (e) { console.error(e); }
  };

  if (loading) return <Loading text="Loading profile..." />;

  // Compute lifetime stats from daily_stats
  const totalSteps = stats.reduce((a,s) => a + (s.total_steps||0), 0);
  const totalCals = stats.reduce((a,s) => a + Number(s.total_calories||0), 0);
  const totalDist = stats.reduce((a,s) => a + Number(s.total_distance_meters||0), 0);
  const totalMins = stats.reduce((a,s) => a + (s.active_minutes||0), 0);
  const avgSteps = stats.length > 0 ? Math.round(totalSteps/stats.length) : 0;
  const avgHR = stats.filter(s=>s.avg_heart_rate).length > 0 ? Math.round(stats.filter(s=>s.avg_heart_rate).reduce((a,s)=>a+s.avg_heart_rate,0)/stats.filter(s=>s.avg_heart_rate).length) : 0;

  // Streak calendar for current month
  const today = new Date();
  const daysInMonth = new Date(today.getFullYear(), today.getMonth()+1, 0).getDate();
  const activeDays = new Set(stats.filter(s => new Date(s.date).getMonth()===today.getMonth()).map(s => new Date(s.date).getDate()));

  return (
    <div style={{ padding: "0 16px 100px" }}>
      <div style={{ padding: "16px 0 24px", textAlign: "center" }}>
        <div style={{ position: "relative", display: "inline-block", marginBottom: 16 }}>
          <div style={{ width: 88, height: 88, borderRadius: 44, background: `linear-gradient(135deg, ${C.pri}, ${C.priL})`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 36, fontWeight: 700, color: "#fff", boxShadow: `0 4px 20px ${C.pri}40` }}>
            {(profile?.full_name||"U").charAt(0).toUpperCase()}</div>
        </div>
        <div style={{ fontSize: 22, fontWeight: 700, color: C.text }}>{profile?.full_name||"Athlete"}</div>
        <div style={{ fontSize: 14, color: C.pri, marginTop: 2 }}>@{profile?.username||user.email.split("@")[0]}</div>
        {profile?.bio && <div style={{ fontSize: 13, color: C.text2, marginTop: 6 }}>{profile.bio}</div>}
        <div style={{ display: "flex", justifyContent: "center", gap: 32, marginTop: 20 }}>
          {[{ l: "Workouts", v: profile?.total_workouts||0 }, { l: "Activities", v: profile?.total_activities||0 }, { l: "Streak", v: `${profile?.current_streak||0}🔥` }].map(s => (
            <div key={s.l} style={{ textAlign: "center" }}><div style={{ fontSize: 20, fontWeight: 700, color: C.text }}>{s.v}</div><div style={{ fontSize: 11, color: C.text2 }}>{s.l}</div></div>
          ))}
        </div>
      </div>

      {/* Streak Calendar */}
      <div style={{ background: C.bgCard, borderRadius: 16, padding: 20, marginBottom: 20, border: `1px solid ${C.bor}` }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
          <div style={{ fontSize: 15, fontWeight: 600, color: C.text }}>Streak Calendar</div>
          <div style={{ fontSize: 12, color: C.text2 }}>{today.toLocaleDateString("en",{month:"long",year:"numeric"})}</div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(7, 1fr)", gap: 6 }}>
          {["M","T","W","T","F","S","S"].map((d,i) => <div key={i} style={{ fontSize: 10, color: C.text3, textAlign: "center", marginBottom: 4 }}>{d}</div>)}
          {Array.from({length: daysInMonth}, (_,i) => {
            const day = i+1; const isToday = day===today.getDate(); const hasAct = activeDays.has(day);
            return (<div key={i} style={{ aspectRatio: "1", borderRadius: 6, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: isToday?700:400, background: hasAct?`${C.pri}${isToday?"40":"20"}`:"transparent", color: isToday?C.pri:hasAct?C.text:C.text3, border: isToday?`2px solid ${C.pri}`:"none" }}>{day}</div>);
          })}
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: "flex", background: C.bgCard, borderRadius: 12, padding: 4, marginBottom: 20, border: `1px solid ${C.bor}` }}>
        {["achievements","apps","stats","settings"].map(t => (
          <button key={t} onClick={() => setActiveTab(t)} style={{ flex: 1, padding: "8px 0", borderRadius: 8, border: "none", cursor: "pointer", fontSize: 13, fontWeight: 600, textTransform: "capitalize", background: activeTab===t?C.pri:"transparent", color: activeTab===t?"#fff":C.text2 }}>{t}</button>
        ))}
      </div>

      {/* Achievements */}
      {activeTab === "achievements" && (
        <div>
          <div style={{ fontSize: 15, fontWeight: 600, color: C.text, marginBottom: 14 }}>
            {userAchievements.length}/{achievementsData.length} Unlocked
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
            {achievementsData.map(a => {
              const earned = userAchievements.includes(a.id);
              return (
                <div key={a.id} style={{ background: C.bgCard, borderRadius: 14, padding: 16, border: `1px solid ${earned?C.pri+"30":C.bor}`, opacity: earned?1:0.6, textAlign: "center" }}>
                  <div style={{ fontSize: 32, marginBottom: 8, filter: earned?"none":"grayscale(1)" }}>{a.icon}</div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: C.text, marginBottom: 4 }}>{a.name}</div>
                  <div style={{ fontSize: 11, color: C.text2, marginBottom: 8 }}>{a.description}</div>
                  {earned ? <div style={{ fontSize: 11, color: C.acc, fontWeight: 600 }}>✓ Earned</div> : <div style={{ fontSize: 11, color: C.text3 }}>Locked</div>}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Connected Apps */}
      {activeTab === "apps" && <ConnectedApps userId={user.id} token={token} />}

      {/* Stats */}
      {activeTab === "stats" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {[{ l: "Total Steps", v: totalSteps.toLocaleString(), i: Footprints, c: C.pri },
            { l: "Total Calories Burned", v: `${Math.round(totalCals).toLocaleString()} kcal`, i: Flame, c: C.danger },
            { l: "Total Distance", v: `${(totalDist/1000).toFixed(1)} km`, i: Route, c: C.accB },
            { l: "Total Active Time", v: `${Math.round(totalMins/60)} hours`, i: Clock, c: C.acc },
            { l: "Avg Steps/Day", v: avgSteps.toLocaleString(), i: Target, c: C.sec },
            { l: "Avg Heart Rate", v: avgHR ? `${avgHR} bpm` : "—", i: Heart, c: "#FF2D55" },
          ].map(({ l,v,i:Icon,c }) => (
            <div key={l} style={{ background: C.bgCard, borderRadius: 14, padding: "14px 16px", border: `1px solid ${C.bor}`, display: "flex", alignItems: "center", gap: 14 }}>
              <div style={{ width: 40, height: 40, borderRadius: 10, background: `${c}15`, display: "flex", alignItems: "center", justifyContent: "center" }}><Icon size={18} color={c}/></div>
              <div style={{ flex: 1 }}><div style={{ fontSize: 12, color: C.text2 }}>{l}</div><div style={{ fontSize: 16, fontWeight: 600, color: C.text }}>{v}</div></div>
            </div>
          ))}
        </div>
      )}

      {/* Settings */}
      {activeTab === "settings" && (
        <div>
          {editing ? (
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              {[{ k: "full_name", l: "Full Name", t: "text" }, { k: "bio", l: "Bio", t: "text" },
                { k: "daily_step_goal", l: "Daily Step Goal", t: "number" }, { k: "daily_calorie_goal", l: "Daily Calorie Goal", t: "number" },
                { k: "daily_active_minutes_goal", l: "Active Minutes Goal", t: "number" }].map(f => (
                <div key={f.k}>
                  <label style={{ fontSize: 13, color: C.text2, display: "block", marginBottom: 6 }}>{f.l}</label>
                  <input type={f.t} value={editForm[f.k]||""} onChange={e => setEditForm({...editForm,[f.k]:f.t==="number"?Number(e.target.value):e.target.value})}
                    style={{ width: "100%", background: C.bgInput, border: `1px solid ${C.bor}`, borderRadius: 12, padding: "12px 14px", color: C.text, fontSize: 15, outline: "none", boxSizing: "border-box" }}/>
                </div>
              ))}
              <div style={{ display: "flex", gap: 10 }}>
                <button onClick={saveProfile} style={{ flex: 1, padding: 14, borderRadius: 14, border: "none", background: C.pri, color: "#fff", fontSize: 15, fontWeight: 600, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 6 }}><Save size={16}/> Save</button>
                <button onClick={() => setEditing(false)} style={{ flex: 1, padding: 14, borderRadius: 14, border: `1px solid ${C.bor}`, background: "transparent", color: C.text2, fontSize: 15, cursor: "pointer" }}>Cancel</button>
              </div>
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              {[{ i: Edit3, l: "Edit Profile", d: "Name, bio, goals", action: () => setEditing(true) },
                { i: Target, l: "Goals", d: `${profile?.daily_step_goal||10000} steps · ${profile?.daily_calorie_goal||500} cal · ${profile?.daily_active_minutes_goal||30} min`, action: () => setEditing(true) },
                { i: Bell, l: "Notifications", d: "Push, reminders, social" },
                { i: Heart, l: "Health Data", d: "Connect devices & apps" },
                { i: Settings, l: "Preferences", d: "Units, theme, privacy" },
                { i: LogOut, l: "Sign Out", d: "", color: C.danger, action: onLogout },
              ].map(({ i:Icon,l,d,color,action }) => (
                <div key={l} onClick={action} style={{ background: C.bgCard, borderRadius: 14, padding: "14px 16px", border: `1px solid ${C.bor}`, display: "flex", alignItems: "center", gap: 14, cursor: action?"pointer":"default" }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: `${color||C.text3}15`, display: "flex", alignItems: "center", justifyContent: "center" }}><Icon size={16} color={color||C.text2}/></div>
                  <div style={{ flex: 1 }}><div style={{ fontSize: 14, fontWeight: 500, color: color||C.text }}>{l}</div>{d&&<div style={{ fontSize: 12, color: C.text2 }}>{d}</div>}</div>
                  <ChevronRight size={16} color={C.text3}/>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

// ============================================
// NOTIFICATIONS SCREEN (LIVE DATA)
// ============================================
const NotificationsScreen = ({ onBack }) => {
  const { token, user } = useAuth();
  const [notifs, setNotifs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadNotifications(); }, []);

  const loadNotifications = async () => {
    setLoading(true);
    try {
      const data = await supabase.query("notifications", token, { filters: `user_id=eq.${user.id}`, order: "created_at.desc", limit: "20" });
      setNotifs(data);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const markRead = async (id) => {
    try {
      await supabase.update("notifications", { is_read: true }, `id=eq.${id}`, token);
      setNotifs(notifs.map(n => n.id===id ? {...n, is_read: true} : n));
    } catch (e) { console.error(e); }
  };

  const typeColor = { streak: "#FF9500", achievement: "#FFD700", social: C.accB, goal_completed: C.acc, reminder: C.text2 };
  const typeIcon = { streak: Flame, achievement: Award, social: ThumbsUp, goal_completed: Target, reminder: Bell };

  if (loading) return <Loading />;

  return (
    <div style={{ padding: "0 16px 100px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "16px 0 20px" }}>
        <button onClick={onBack} style={{ width: 36, height: 36, borderRadius: 18, background: C.bgCard, border: `1px solid ${C.bor}`, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}><ChevronLeft size={18} color={C.text}/></button>
        <div style={{ fontSize: 22, fontWeight: 700, color: C.text }}>Notifications</div>
        <div style={{ marginLeft: "auto", fontSize: 13, color: C.text2 }}>{notifs.filter(n=>!n.is_read).length} unread</div>
      </div>
      {notifs.length === 0 ? <EmptyState icon={Bell} title="No notifications" subtitle="You're all caught up!" /> : (
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {notifs.map(n => {
            const Icon = typeIcon[n.type] || Bell; const color = typeColor[n.type] || C.pri;
            return (
              <div key={n.id} onClick={() => !n.is_read && markRead(n.id)} style={{ background: n.is_read?C.bgCard:`${color}08`, borderRadius: 14, padding: "14px 16px", border: `1px solid ${n.is_read?C.bor:color+"30"}`, display: "flex", gap: 14, cursor: !n.is_read?"pointer":"default" }}>
                <div style={{ width: 40, height: 40, borderRadius: 12, background: `${color}15`, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}><Icon size={18} color={color}/></div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 2 }}>
                    <div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{n.title}</div>
                    {!n.is_read && <div style={{ width: 8, height: 8, borderRadius: 4, background: C.pri }}/>}</div>
                  <div style={{ fontSize: 13, color: C.text2, marginBottom: 4 }}>{n.body}</div>
                  <div style={{ fontSize: 11, color: C.text3 }}>{timeAgo(n.created_at)}</div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

// ============================================
// MAIN APP WITH AUTH
// ============================================
export default function StrideFitnessApp() {
  const [session, setSession] = useState(null);
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [activeTab, setActiveTab] = useState("home");
  const [showNotifs, setShowNotifs] = useState(false);
  const [initializing, setInitializing] = useState(true);

  // Check for existing session or OAuth redirect
  useEffect(() => {
    // Check for OAuth redirect (tokens in URL hash)
    const hashParams = new URLSearchParams(window.location.hash.substring(1));
    const accessToken = hashParams.get("access_token");
    if (accessToken) {
      // Clear the hash from URL
      window.history.replaceState(null, "", window.location.pathname);
      // Fetch user with the token
      (async () => {
        try {
          const user = await supabase.getUser(accessToken);
          if (user && user.id) {
            const data = { access_token: accessToken, user, token_type: "bearer" };
            // Try to seed demo data for new OAuth users
            try { await supabase.rpc("seed_demo_data_for_user", { p_user_id: user.id }, accessToken); } catch (e) { console.log("Seed skipped:", e); }
            handleAuth(data);
          } else { setInitializing(false); }
        } catch { setInitializing(false); }
      })();
      return;
    }

    // Check for stored session
    const stored = sessionStorage.getItem("stride_session");
    if (stored) {
      try {
        const s = JSON.parse(stored);
        setSession(s);
        setUser(s.user);
        loadProfile(s.user.id, s.access_token);
      } catch { setInitializing(false); }
    } else { setInitializing(false); }
  }, []);

  const loadProfile = async (userId, token) => {
    try {
      const profiles = await supabase.query("profiles", token, { filters: `id=eq.${userId}`, limit: "1" });
      setProfile(profiles[0] || null);
    } catch (e) { console.error(e); }
    setInitializing(false);
  };

  const refreshProfile = async () => {
    if (session && user) await loadProfile(user.id, session.access_token);
  };

  const handleAuth = (data) => {
    setSession(data);
    setUser(data.user);
    sessionStorage.setItem("stride_session", JSON.stringify(data));
    loadProfile(data.user.id, data.access_token);
  };

  const handleLogout = () => {
    setSession(null); setUser(null); setProfile(null);
    sessionStorage.removeItem("stride_session");
    setActiveTab("home");
  };

  const handleNavigate = useCallback((target) => {
    if (target === "notifications") setShowNotifs(true);
    else setActiveTab(target);
  }, []);

  const tabs = [
    { key: "home", label: "Home", icon: Home },
    { key: "activity", label: "Activity", icon: Activity },
    { key: "workout", label: "Workout", icon: Dumbbell },
    { key: "leaderboard", label: "Ranks", icon: Trophy },
    { key: "profile", label: "Profile", icon: User },
  ];

  if (initializing) return (
    <div style={{ minHeight: "100vh", background: C.bg, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: "-apple-system, sans-serif" }}>
      <div style={{ textAlign: "center" }}>
        <div style={{ width: 64, height: 64, borderRadius: 16, background: `linear-gradient(135deg, ${C.pri}, ${C.priL})`, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px", boxShadow: `0 8px 32px ${C.pri}40` }}>
          <Zap size={32} color="#fff" /></div>
        <div style={{ fontSize: 20, fontWeight: 700, color: C.text }}>STRIDE</div>
        <Loader2 size={20} color={C.pri} style={{ animation: "spin 1s linear infinite", marginTop: 16 }} />
        <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
      </div>
    </div>
  );

  if (!session) return <AuthScreen onAuth={handleAuth} />;

  const authValue = { token: session.access_token, user, profile, refreshProfile };

  return (
    <AuthContext.Provider value={authValue}>
      <div style={{ maxWidth: 430, margin: "0 auto", background: C.bg, minHeight: "100vh", fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif", position: "relative", color: C.text }}>
        {/* Status Bar */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 20px 4px", fontSize: 14, fontWeight: 600, color: C.text }}>
          <span>{new Date().toLocaleTimeString("en",{hour:"2-digit",minute:"2-digit",hour12:false})}</span>
          <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
            <svg width="16" height="12" viewBox="0 0 16 12"><path d="M1 4h2v8H1zM5 2h2v10H5zM9 0h2v12H9zM13 3h2v9h-2z" fill={C.text}/></svg>
            <div style={{ width: 25, height: 12, borderRadius: 3, border: `1px solid ${C.text}60`, position: "relative", display: "flex", alignItems: "center", padding: 1 }}>
              <div style={{ width: "70%", height: "100%", borderRadius: 2, background: C.acc }}/></div>
          </div>
        </div>

        {/* Content */}
        <div style={{ overflowY: "auto", height: "calc(100vh - 130px)" }}>
          {showNotifs ? <NotificationsScreen onBack={() => setShowNotifs(false)} /> : (<>
            {activeTab === "home" && <DashboardScreen onNavigate={handleNavigate} />}
            {activeTab === "activity" && <ActivityScreen />}
            {activeTab === "workout" && <WorkoutScreen />}
            {activeTab === "leaderboard" && <LeaderboardScreen />}
            {activeTab === "profile" && <ProfileScreen onLogout={handleLogout} />}
          </>)}
        </div>

        {/* Tab Bar */}
        <div style={{ position: "fixed", bottom: 0, left: "50%", transform: "translateX(-50%)", width: "100%", maxWidth: 430, background: `${C.bg}F2`, backdropFilter: "blur(20px)", borderTop: `1px solid ${C.bor}`, display: "flex", justifyContent: "space-around", padding: "8px 0 28px", zIndex: 100 }}>
          {tabs.map(({ key, label, icon: Icon }) => {
            const isActive = activeTab === key && !showNotifs;
            return (
              <button key={key} onClick={() => { setActiveTab(key); setShowNotifs(false); }}
                style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4, background: "none", border: "none", cursor: "pointer", padding: "4px 12px" }}>
                <div style={{ position: "relative" }}>
                  <Icon size={22} color={isActive?C.pri:C.text3} strokeWidth={isActive?2.5:1.5}/>
                  {isActive && <div style={{ position: "absolute", top: -4, left: "50%", transform: "translateX(-50%)", width: 4, height: 4, borderRadius: 2, background: C.pri }}/>}
                </div>
                <span style={{ fontSize: 10, fontWeight: isActive?600:400, color: isActive?C.pri:C.text3 }}>{label}</span>
              </button>
            );
          })}
        </div>
      </div>
      <style>{`input::placeholder { color: ${C.text3}; } @keyframes spin { to { transform: rotate(360deg) } }`}</style>
    </AuthContext.Provider>
  );
}
