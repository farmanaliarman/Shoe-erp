import { useState, useEffect, useCallback, useRef } from "react";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = "https://qljqfiyamrmrxvcrwopy.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsanFmaXlhbXJtcnh2Y3J3b3B5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NzY5NTcsImV4cCI6MjA5NzU1Mjk1N30.smMb5JbjU5qVg8c0lXIeRcNCJMc8vWjiZVEuNIAXzy0";
const db = createClient(SUPABASE_URL, SUPABASE_KEY);

// ─── helpers ────────────────────────────────────────────────
const today = () => new Date().toISOString().slice(0, 10);
const fmt = (n) => "₹" + (+(n || 0)).toLocaleString("en-IN", { maximumFractionDigits: 0 });
const num = (n, d = 2) => { const v = +(n || 0); return v % 1 === 0 ? String(v) : v.toFixed(d); };
const daysAgo = (s) => { const d = new Date(s + "T00:00:00"), n = new Date(); n.setHours(0,0,0,0); return Math.round((n-d)/86400000); };
const inRange = (s, days) => { const d = daysAgo(s); return d >= 0 && d <= days; };

// ─── shared UI ──────────────────────────────────────────────
const C = {
  ink: "#1C1917", muted: "#78716C", border: "#E7E5E4",
  bg: "#FAFAF9", card: "#FFFFFF",
  accent: "#B45309", accentDark: "#92400E", accentLight: "#FEF3C7",
  good: "#059669", bad: "#DC2626", warn: "#D97706",
};
const st = {
  card: { background: C.card, border: `1px solid ${C.border}`, borderRadius: 12, padding: 16 },
  btn: { background: C.accent, color: "#fff", border: "none", borderRadius: 8, padding: "7px 14px", fontSize: 13, fontWeight: 600, cursor: "pointer", display: "inline-flex", alignItems: "center", gap: 5 },
  btnGhost: { background: C.bg, color: C.ink, border: `1px solid ${C.border}`, borderRadius: 8, padding: "7px 14px", fontSize: 13, fontWeight: 500, cursor: "pointer", display: "inline-flex", alignItems: "center", gap: 5 },
  btnDanger: { background: "#FFF1F2", color: C.bad, border: `1px solid #FECDD3`, borderRadius: 8, padding: "5px 10px", fontSize: 12, fontWeight: 600, cursor: "pointer" },
  input: { border: `1px solid ${C.border}`, borderRadius: 8, padding: "7px 10px", fontSize: 13, width: "100%", outline: "none", fontFamily: "inherit" },
  select: { border: `1px solid ${C.border}`, borderRadius: 8, padding: "7px 10px", fontSize: 13, width: "100%", outline: "none", fontFamily: "inherit", background: "#fff" },
  label: { fontSize: 11, fontWeight: 700, letterSpacing: "0.05em", textTransform: "uppercase", color: C.muted, display: "block", marginBottom: 4 },
  th: { textAlign: "left", fontSize: 11, fontWeight: 700, letterSpacing: "0.05em", textTransform: "uppercase", color: C.muted, padding: "8px 12px", background: C.bg, borderBottom: `1px solid ${C.border}` },
  td: { padding: "8px 12px", fontSize: 13, color: C.ink, borderBottom: `1px solid ${C.border}` },
};
const Inp = (p) => <input style={st.input} {...p} />;
const Sel = ({ children, ...p }) => <select style={st.select} {...p}>{children}</select>;
const Btn = ({ children, style, ...p }) => <button style={{ ...st.btn, ...style }} {...p}>{children}</button>;
const Ghost = ({ children, style, ...p }) => <button style={{ ...st.btnGhost, ...style }} {...p}>{children}</button>;
const Danger = ({ children, ...p }) => <button style={st.btnDanger} {...p}>{children}</button>;
const Tag = ({ children, color = C.muted }) => <span style={{ background: "#F5F5F4", color, border: `1px solid ${C.border}`, borderRadius: 99, padding: "2px 8px", fontSize: 11, fontWeight: 600 }}>{children}</span>;
const Lbl = ({ children }) => <label style={st.label}>{children}</label>;
const Row = ({ label, val, bold, green, red, sub }) => (
  <tr>
    <td style={{ ...st.td, color: sub ? C.muted : C.ink }}>{label}</td>
    <td style={{ ...st.td, textAlign: "right", fontFamily: "monospace", fontWeight: bold ? 700 : 400, color: green ? C.good : red ? C.bad : C.ink }}>{val}</td>
  </tr>
);
const StatCard = ({ title, value, sub, green, red }) => (
  <div style={{ ...st.card, borderColor: green ? "#A7F3D0" : red ? "#FECACA" : C.border, background: green ? "#F0FDF4" : red ? "#FFF5F5" : C.card }}>
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase", color: C.muted }}>{title}</div>
    <div style={{ fontSize: 22, fontWeight: 800, color: green ? C.good : red ? C.bad : C.ink, fontFamily: "monospace", marginTop: 4 }}>{value}</div>
    {sub && <div style={{ fontSize: 11, color: C.muted, marginTop: 2 }}>{sub}</div>}
  </div>
);
const SectionHead = ({ title, action }) => (
  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14 }}>
    <h2 style={{ margin: 0, fontSize: 18, fontWeight: 700, color: C.accentDark }}>{title}</h2>
    {action}
  </div>
);
const Table = ({ heads, children, empty }) => (
  <div style={{ overflowX: "auto", border: `1px solid ${C.border}`, borderRadius: 12 }}>
    <table style={{ width: "100%", borderCollapse: "collapse" }}>
      <thead><tr>{heads.map(h => <th key={h} style={st.th}>{h}</th>)}</tr></thead>
      <tbody>{children}</tbody>
    </table>
    {empty && <div style={{ textAlign: "center", padding: 32, color: C.muted, fontSize: 13 }}>{empty}</div>}
  </div>
);
const Grid = ({ cols = 2, children }) => (
  <div style={{ display: "grid", gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: 12 }}>{children}</div>
);
const FormBox = ({ title, children, onSubmit }) => (
  <div style={{ ...st.card, display: "flex", flexDirection: "column", gap: 10 }}>
    {title && <div style={{ fontWeight: 700, fontSize: 14, color: C.ink, marginBottom: 2 }}>{title}</div>}
    {children}
    {onSubmit && <Btn onClick={onSubmit} style={{ marginTop: 4, justifyContent: "center" }}>Save</Btn>}
  </div>
);
const Loading = () => <div style={{ padding: 48, textAlign: "center", color: C.muted }}>Loading…</div>;
const Toast = ({ msg, type }) => msg ? (
  <div style={{ position: "fixed", bottom: 20, right: 20, background: type === "error" ? C.bad : C.good, color: "#fff", padding: "10px 18px", borderRadius: 10, fontSize: 13, fontWeight: 600, zIndex: 9999, boxShadow: "0 4px 12px rgba(0,0,0,0.2)" }}>{msg}</div>
) : null;

// ─── main app ───────────────────────────────────────────────
const TABS = [
  "Dashboard","Raw Materials","Products","Labor",
  "Material Issued","Production","Advances","Labor Ledger",
  "Purchases","Suppliers","Customers","Sales","Payments","Supplier Payments",
  "Expenses","Reports","Settings"
];

export default function App() {
  const [tab, setTab] = useState("Dashboard");
  const [data, setData] = useState({});
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);
  const toastTimer = useRef(null);

  const showToast = useCallback((msg, type = "ok") => {
    setToast({ msg, type });
    clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(null), 2800);
  }, []);

  const load = useCallback(async () => {
    try {
      const tables = ["settings","colors","categories","raw_materials","suppliers","purchases",
        "products","labor","material_issued","production","advances",
        "customers","sales","payments","supplier_payments","expenses"];
      const results = await Promise.all(tables.map(t => db.from(t).select("*").order("id", { ascending: true, nullsFirst: true })));
      const d = {};
      tables.forEach((t, i) => { d[t] = results[i].data || []; });
      d.settings = d.settings[0] || { business_name: "My Shoe Unit", cash_in_hand: 0 };
      setData(d);
    } catch(e) { showToast("Load error: " + e.message, "error"); }
    setLoading(false);
  }, [showToast]);

  useEffect(() => { load(); }, [load]);

  // Real-time subscriptions for multi-user sync
  useEffect(() => {
    const tables = ["raw_materials","suppliers","purchases","products","labor",
      "material_issued","production","advances","customers","sales",
      "payments","supplier_payments","expenses","settings","categories"];
    const subs = tables.map(t =>
      db.channel(`rt_${t}`).on("postgres_changes", { event: "*", schema: "public", table: t }, () => load()).subscribe()
    );
    return () => subs.forEach(s => db.removeChannel(s));
  }, [load]);

  const refresh = useCallback(async (fn) => {
    try { await fn(); showToast("Saved"); await load(); }
    catch(e) { showToast(e.message, "error"); }
  }, [load, showToast]);

  if (loading) return <Loading />;

  const tabProps = { data, db, refresh, showToast, load };

  return (
    <div style={{ minHeight: "100vh", background: C.bg, fontFamily: "system-ui, sans-serif", color: C.ink }}>
      {/* Header */}
      <div style={{ background: C.accentDark, color: "#fff", padding: "12px 20px", display: "flex", alignItems: "center", gap: 12, position: "sticky", top: 0, zIndex: 100, boxShadow: "0 2px 8px rgba(0,0,0,0.25)" }}>
        <div style={{ width: 36, height: 36, borderRadius: "50%", background: C.accent, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 900, fontSize: 14 }}>UF</div>
        <div>
          <div style={{ fontWeight: 800, fontSize: 16, letterSpacing: "-0.01em" }}>{data.settings.business_name}</div>
          <div style={{ fontSize: 11, opacity: 0.7 }}>Shoe Upper Ledger · Live sync active</div>
        </div>
      </div>
      {/* Nav */}
      <div style={{ background: "#fff", borderBottom: `1px solid ${C.border}`, overflowX: "auto", position: "sticky", top: 60, zIndex: 99 }}>
        <div style={{ display: "flex", gap: 2, padding: "8px 12px", minWidth: "max-content" }}>
          {TABS.map(t => (
            <button key={t} onClick={() => setTab(t)} style={{ padding: "6px 12px", borderRadius: 20, border: "none", fontSize: 12, fontWeight: 600, cursor: "pointer", whiteSpace: "nowrap", background: tab === t ? C.accent : "transparent", color: tab === t ? "#fff" : C.muted, transition: "all 0.15s" }}>{t}</button>
          ))}
        </div>
      </div>
      {/* Content */}
      <div style={{ maxWidth: 1100, margin: "0 auto", padding: "20px 16px" }}>
        {tab === "Dashboard" && <DashboardTab {...tabProps} />}
        {tab === "Raw Materials" && <RawMaterialsTab {...tabProps} />}
        {tab === "Products" && <ProductsTab {...tabProps} />}
        {tab === "Labor" && <LaborTab {...tabProps} />}
        {tab === "Material Issued" && <MaterialIssuedTab {...tabProps} />}
        {tab === "Production" && <ProductionTab {...tabProps} />}
        {tab === "Advances" && <AdvancesTab {...tabProps} />}
        {tab === "Labor Ledger" && <LaborLedgerTab {...tabProps} />}
        {tab === "Purchases" && <PurchasesTab {...tabProps} />}
        {tab === "Suppliers" && <SuppliersTab {...tabProps} />}
        {tab === "Customers" && <CustomersTab {...tabProps} />}
        {tab === "Sales" && <SalesTab {...tabProps} />}
        {tab === "Payments" && <PaymentsTab {...tabProps} />}
        {tab === "Supplier Payments" && <SupplierPaymentsTab {...tabProps} />}
        {tab === "Expenses" && <ExpensesTab {...tabProps} />}
        {tab === "Reports" && <ReportsTab {...tabProps} />}
        {tab === "Settings" && <SettingsTab {...tabProps} />}
      </div>
      <Toast {...(toast || { msg: null })} />
    </div>
  );
}

// ─── Dashboard ───────────────────────────────────────────────
function DashboardTab({ data }) {
  const { sales = [], expenses = [], production = [], purchases = [], raw_materials = [], products = [] } = data;
  const m30 = (arr, field, days = 29) => arr.filter(r => inRange(r.date, days)).reduce((s, r) => s + +(r[field] || 0), 0);
  const rev = m30(sales, "net_total");
  const rawVal = raw_materials.reduce((s, r) => s + +(r.opening_stock||0) * +(r.cost_per_unit||0), 0);
  const custBal = data.customers?.reduce((s, c) => {
    const sold = sales.filter(r => r.customer_id === c.id).reduce((a, r) => a + +(r.net_total||0), 0);
    const paid = (data.payments || []).filter(r => r.customer_id === c.id).reduce((a, r) => a + +(r.amount||0), 0);
    return s + +(c.opening_balance||0) + sold - paid;
  }, 0) || 0;
  const suppBal = data.suppliers?.reduce((s, sup) => {
    const bought = purchases.filter(r => r.supplier_id === sup.id).reduce((a, r) => a + +(r.total_value||0), 0);
    const paid2 = (data.supplier_payments || []).filter(r => r.supplier_id === sup.id).reduce((a, r) => a + +(r.amount||0), 0);
    return s + +(sup.opening_balance||0) + bought - paid2;
  }, 0) || 0;
  const nwc = rawVal + custBal - suppBal + +(data.settings?.cash_in_hand||0);
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <SectionHead title={`${data.settings?.business_name} — Overview`} />
      <Grid cols={2}>
        <StatCard title="Revenue (30 days)" value={fmt(rev)} sub={`${sales.filter(r=>inRange(r.date,29)).length} sales`} />
        <StatCard title="Customer Receivable" value={fmt(custBal)} green={custBal > 0} />
        <StatCard title="Supplier Payable" value={fmt(suppBal)} red={suppBal > 0} />
        <StatCard title="Net Working Capital" value={fmt(nwc)} green={nwc > 0} sub="Stock + Receivable − Payable + Cash" />
      </Grid>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <div style={st.card}>
          <div style={{ fontWeight: 700, marginBottom: 10 }}>Raw Material Stock (top items)</div>
          {raw_materials.filter(r => +(r.opening_stock||0) > 0).slice(0,8).map(r => (
            <div key={r.id} style={{ display: "flex", justifyContent: "space-between", fontSize: 13, padding: "4px 0", borderBottom: `1px solid ${C.border}` }}>
              <span>{r.display_name}</span>
              <span style={{ fontFamily: "monospace" }}>{r.opening_stock} {r.unit} · {fmt(+(r.opening_stock||0) * +(r.cost_per_unit||0))}</span>
            </div>
          ))}
          {raw_materials.filter(r=>+(r.opening_stock||0)>0).length === 0 && <div style={{color:C.muted,fontSize:13}}>No stock entered yet.</div>}
        </div>
        <div style={st.card}>
          <div style={{ fontWeight: 700, marginBottom: 10 }}>Products in Stock</div>
          {products.map(p => {
            const produced = (production||[]).filter(r=>r.product_id===p.id).reduce((s,r)=>s++(r.quantity||0),0);
            const sold = sales.filter(r=>r.product_id===p.id).reduce((s,r)=>s++(r.quantity||0),0);
            const stock = +(p.opening_stock||0) + produced - sold;
            return (
              <div key={p.id} style={{ display: "flex", justifyContent: "space-between", fontSize: 13, padding: "4px 0", borderBottom: `1px solid ${C.border}` }}>
                <span>{p.name} <Tag>{p.color}</Tag></span>
                <span style={{ fontFamily: "monospace", color: stock <= 0 ? C.bad : C.ink }}>{stock} pcs</span>
              </div>
            );
          })}
          {products.length === 0 && <div style={{color:C.muted,fontSize:13}}>No products yet.</div>}
        </div>
      </div>
    </div>
  );
}

// ─── Raw Materials ────────────────────────────────────────────
function RawMaterialsTab({ data, db, refresh }) {
  const [form, setForm] = useState({ material_name:"Ragzine", color:"Black", unit:"meter", opening_stock:0, cost_per_unit:0, reorder_level:30 });
  const rms = data.raw_materials || [];
  const save = () => refresh(async () => {
    const { error } = await db.from("raw_materials").insert([form]);
    if (error) throw error;
  });
  const del = (id) => refresh(async () => { const {error} = await db.from("raw_materials").delete().eq("id",id); if(error) throw error; });
  const upd = (id, field, val) => refresh(async () => { const {error} = await db.from("raw_materials").update({[field]: val}).eq("id",id); if(error) throw error; });
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      <SectionHead title="Raw Materials" />
      <FormBox title="Add Material">
        <Grid cols={3}>
          <div><Lbl>Material Name</Lbl><Inp value={form.material_name} onChange={e=>setForm({...form,material_name:e.target.value})} /></div>
          <div><Lbl>Color</Lbl>
            <Sel value={form.color} onChange={e=>setForm({...form,color:e.target.value})}>
              {["Black","Green","Brown","Mustard","Cream","Maroon","Pink","Zink","Purple","Grey","No Color"].map(c=><option key={c}>{c}</option>)}
            </Sel>
          </div>
          <div><Lbl>Unit</Lbl><Inp value={form.unit} onChange={e=>setForm({...form,unit:e.target.value})} /></div>
          <div><Lbl>Opening Stock</Lbl><Inp type="number" value={form.opening_stock} onChange={e=>setForm({...form,opening_stock:+e.target.value})} /></div>
          <div><Lbl>Cost per Unit (₹)</Lbl><Inp type="number" value={form.cost_per_unit} onChange={e=>setForm({...form,cost_per_unit:+e.target.value})} /></div>
          <div><Lbl>Reorder Level</Lbl><Inp type="number" value={form.reorder_level} onChange={e=>setForm({...form,reorder_level:+e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Material</Btn>
      </FormBox>
      <Table heads={["Name","Color","Unit","Opening Stock","Cost/Unit","Stock Value",""]}>
        {rms.length ? rms.map(r => (
          <tr key={r.id}>
            <td style={st.td}>{r.material_name}</td>
            <td style={st.td}><Tag>{r.color}</Tag></td>
            <td style={st.td}>{r.unit}</td>
            <td style={st.td}><Inp type="number" defaultValue={r.opening_stock} onBlur={e=>upd(r.id,"opening_stock",+e.target.value)} style={{...st.input,width:90}} /></td>
            <td style={st.td}><Inp type="number" defaultValue={r.cost_per_unit} onBlur={e=>upd(r.id,"cost_per_unit",+e.target.value)} style={{...st.input,width:90}} /></td>
            <td style={{...st.td,fontFamily:"monospace"}}>{fmt(+(r.opening_stock||0)*+(r.cost_per_unit||0))}</td>
            <td style={st.td}><Danger onClick={()=>del(r.id)}>✕</Danger></td>
          </tr>
        )) : null}
      </Table>
      {!rms.length && <div style={{color:C.muted,fontSize:13,textAlign:"center",padding:24}}>No raw materials yet. The 23 default materials (Ragzine×10, Mash×10, Daimod, Naki Feeta, Pipe) are pre-inserted by the SQL setup script.</div>}
    </div>
  );
}

// ─── Categories ───────────────────────────────────────────────
// (Embedded in Settings for simplicity, but accessible via Settings tab)

// ─── Products ────────────────────────────────────────────────
function ProductsTab({ data, db, refresh }) {
  const { products = [], categories = [], production = [], sales = [] } = data;
  const [form, setForm] = useState({ name:"01", category:"Adult", color:"Black", selling_price:0, opening_stock:0 });
  const save = () => refresh(async () => { const {error} = await db.from("products").insert([form]); if(error) throw error; });
  const del = (id) => refresh(async () => { const {error} = await db.from("products").delete().eq("id",id); if(error) throw error; });
  const upd = (id, f, v) => refresh(async () => { const {error} = await db.from("products").update({[f]:v}).eq("id",id); if(error) throw error; });
  const stock = (p) => +(p.opening_stock||0) + production.filter(r=>r.product_id===p.id).reduce((s,r)=>s++(r.quantity||0),0) - sales.filter(r=>r.product_id===p.id).reduce((s,r)=>s++(r.quantity||0),0);
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Products" />
      <FormBox title="Add Product">
        <Grid cols={3}>
          <div><Lbl>Product Name (e.g. 01)</Lbl><Inp value={form.name} onChange={e=>setForm({...form,name:e.target.value})} /></div>
          <div><Lbl>Category</Lbl>
            <Sel value={form.category} onChange={e=>setForm({...form,category:e.target.value})}>
              {categories.map(c=><option key={c.id}>{c.name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Color</Lbl>
            <Sel value={form.color} onChange={e=>setForm({...form,color:e.target.value})}>
              {["Black","Green","Brown","Mustard","Cream","Maroon","Pink","Zink","Purple","Grey"].map(c=><option key={c}>{c}</option>)}
            </Sel>
          </div>
          <div><Lbl>Selling Price (₹/dozen)</Lbl><Inp type="number" value={form.selling_price} onChange={e=>setForm({...form,selling_price:+e.target.value})} /></div>
          <div><Lbl>Opening Stock (dozens)</Lbl><Inp type="number" value={form.opening_stock} onChange={e=>setForm({...form,opening_stock:+e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Product</Btn>
      </FormBox>
      <Table heads={["Name","Category","Color","Selling Price","Opening Stock","Current Stock",""]}>
        {products.map(p=>(
          <tr key={p.id}>
            <td style={st.td}>{p.name}</td>
            <td style={st.td}><Tag>{p.category}</Tag></td>
            <td style={st.td}><Tag>{p.color}</Tag></td>
            <td style={st.td}><Inp type="number" defaultValue={p.selling_price} onBlur={e=>upd(p.id,"selling_price",+e.target.value)} style={{...st.input,width:100}} /></td>
            <td style={st.td}><Inp type="number" defaultValue={p.opening_stock} onBlur={e=>upd(p.id,"opening_stock",+e.target.value)} style={{...st.input,width:80}} /></td>
            <td style={{...st.td,fontFamily:"monospace",fontWeight:700,color:stock(p)<=0?C.bad:C.ink}}>{stock(p)}</td>
            <td style={st.td}><Danger onClick={()=>del(p.id)}>✕</Danger></td>
          </tr>
        ))}
      </Table>
      {!products.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No products yet. Add your designs above (01, 02, 03…).</div>}
    </div>
  );
}

// ─── Labor ───────────────────────────────────────────────────
function LaborTab({ data, db, refresh }) {
  const { labor = [], categories = [] } = data;
  const adultRate = categories.find(c=>c.name==="Adult")?.wage_rate || 30;
  const kidsRate = categories.find(c=>c.name==="Kids")?.wage_rate || 20;
  const [form, setForm] = useState({ name:"", phone:"", adult_wage_per_pc: adultRate, kids_wage_per_pc: kidsRate, opening_balance_payable:0 });
  const save = () => refresh(async () => { if(!form.name) throw new Error("Name required"); const {error} = await db.from("labor").insert([form]); if(error) throw error; });
  const del = (id) => refresh(async () => { const {error} = await db.from("labor").delete().eq("id",id); if(error) throw error; });
  const upd = (id,f,v) => refresh(async () => { const {error} = await db.from("labor").update({[f]:v}).eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Labor Roster" />
      <FormBox title="Add Worker">
        <Grid cols={3}>
          <div><Lbl>Name</Lbl><Inp value={form.name} onChange={e=>setForm({...form,name:e.target.value})} /></div>
          <div><Lbl>Phone / Note</Lbl><Inp value={form.phone} onChange={e=>setForm({...form,phone:e.target.value})} /></div>
          <div><Lbl>Adult Wage / pc (₹)</Lbl><Inp type="number" value={form.adult_wage_per_pc} onChange={e=>setForm({...form,adult_wage_per_pc:+e.target.value})} /></div>
          <div><Lbl>Kids Wage / pc (₹)</Lbl><Inp type="number" value={form.kids_wage_per_pc} onChange={e=>setForm({...form,kids_wage_per_pc:+e.target.value})} /></div>
          <div><Lbl>Opening Balance Payable (₹)</Lbl><Inp type="number" value={form.opening_balance_payable} onChange={e=>setForm({...form,opening_balance_payable:+e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Worker</Btn>
      </FormBox>
      <Table heads={["Name","Phone","Adult ₹/pc","Kids ₹/pc","Opening Balance",""]}>
        {labor.map(l=>(
          <tr key={l.id}>
            <td style={st.td}>{l.name}</td>
            <td style={st.td}>{l.phone}</td>
            <td style={st.td}><Inp type="number" defaultValue={l.adult_wage_per_pc} onBlur={e=>upd(l.id,"adult_wage_per_pc",+e.target.value)} style={{...st.input,width:80}} /></td>
            <td style={st.td}><Inp type="number" defaultValue={l.kids_wage_per_pc} onBlur={e=>upd(l.id,"kids_wage_per_pc",+e.target.value)} style={{...st.input,width:80}} /></td>
            <td style={st.td}><Inp type="number" defaultValue={l.opening_balance_payable} onBlur={e=>upd(l.id,"opening_balance_payable",+e.target.value)} style={{...st.input,width:100}} /></td>
            <td style={st.td}><Danger onClick={()=>del(l.id)}>✕</Danger></td>
          </tr>
        ))}
      </Table>
      {!labor.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No workers yet.</div>}
    </div>
  );
}

// ─── Material Issued ─────────────────────────────────────────
function MaterialIssuedTab({ data, db, refresh }) {
  const { labor=[], raw_materials=[], material_issued=[] } = data;
  const [form, setForm] = useState({ date:today(), labor_id:"", material_id:"", quantity:0 });
  const save = () => refresh(async () => {
    if(!form.labor_id||!form.material_id) throw new Error("Pick worker and material");
    const {error} = await db.from("material_issued").insert([{...form, labor_id:+form.labor_id, material_id:+form.material_id}]);
    if(error) throw error;
  });
  const del = (id) => refresh(async () => { const {error} = await db.from("material_issued").delete().eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Material Issued to Labor" />
      <FormBox title="Issue Material">
        <Grid cols={2}>
          <div><Lbl>Date</Lbl><Inp type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} /></div>
          <div><Lbl>Worker</Lbl>
            <Sel value={form.labor_id} onChange={e=>setForm({...form,labor_id:e.target.value})}>
              <option value="">-- pick worker --</option>
              {labor.map(l=><option key={l.id} value={l.id}>{l.name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Material</Lbl>
            <Sel value={form.material_id} onChange={e=>setForm({...form,material_id:e.target.value})}>
              <option value="">-- pick material --</option>
              {raw_materials.map(r=><option key={r.id} value={r.id}>{r.display_name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Quantity</Lbl><Inp type="number" value={form.quantity} onChange={e=>setForm({...form,quantity:+e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Issue</Btn>
      </FormBox>
      <Table heads={["Date","Worker","Material","Qty",""]}>
        {material_issued.slice().reverse().map(r=>{
          const l = labor.find(x=>x.id===r.labor_id);
          const m = raw_materials.find(x=>x.id===r.material_id);
          return (
            <tr key={r.id}>
              <td style={st.td}>{r.date}</td>
              <td style={st.td}>{l?.name || "—"}</td>
              <td style={st.td}>{m?.display_name || "—"}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{r.quantity}</td>
              <td style={st.td}><Danger onClick={()=>del(r.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!material_issued.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No material issued yet.</div>}
    </div>
  );
}

// ─── Production ──────────────────────────────────────────────
function ProductionTab({ data, db, refresh }) {
  const { labor=[], products=[], production=[], categories=[] } = data;
  const [form, setForm] = useState({ date:today(), labor_id:"", product_id:"", quantity:0 });
  const save = () => refresh(async () => {
    if(!form.labor_id||!form.product_id||!+form.quantity) throw new Error("Fill all fields");
    const lid = +form.labor_id, pid = +form.product_id;
    const prod = products.find(p=>p.id===pid);
    const worker = labor.find(l=>l.id===lid);
    const cat = categories.find(c=>c.name===prod?.category);
    const qty = +form.quantity;
    const isAdult = prod?.category === "Adult";
    const wage = qty * (isAdult ? +(worker?.adult_wage_per_pc||0) : +(worker?.kids_wage_per_pc||0));
    const row = {
      date: form.date, labor_id: lid, product_id: pid, quantity: qty,
      wage_earned: wage,
      ragzine_used: qty * +(cat?.ragzine_per_pc||0),
      mash_used: qty * +(cat?.mash_per_pc||0),
      daimod_used: qty * +(cat?.daimod_per_pc||0),
      naki_feeta_used: qty * +(cat?.naki_feeta_per_pc||0),
      pipe_used: qty * +(cat?.pipe_per_pc||0),
    };
    const {error} = await db.from("production").insert([row]);
    if(error) throw error;
  });
  const del = (id) => refresh(async () => { const {error} = await db.from("production").delete().eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Production" />
      <FormBox title="Log Production">
        <Grid cols={2}>
          <div><Lbl>Date</Lbl><Inp type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} /></div>
          <div><Lbl>Worker</Lbl>
            <Sel value={form.labor_id} onChange={e=>setForm({...form,labor_id:e.target.value})}>
              <option value="">-- pick worker --</option>
              {labor.map(l=><option key={l.id} value={l.id}>{l.name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Product</Lbl>
            <Sel value={form.product_id} onChange={e=>setForm({...form,product_id:e.target.value})}>
              <option value="">-- pick product --</option>
              {products.map(p=><option key={p.id} value={p.id}>{p.name} ({p.category} · {p.color})</option>)}
            </Sel>
          </div>
          <div><Lbl>Quantity (dozens)</Lbl><Inp type="number" value={form.quantity} onChange={e=>setForm({...form,quantity:+e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Log Production</Btn>
      </FormBox>
      <Table heads={["Date","Worker","Product","Qty","Wage Earned","Ragzine","Mash","Daimod","Naki Feeta","Pipe",""]}>
        {production.slice().reverse().map(r=>{
          const l = labor.find(x=>x.id===r.labor_id);
          const p = products.find(x=>x.id===r.product_id);
          return (
            <tr key={r.id}>
              <td style={st.td}>{r.date}</td>
              <td style={st.td}>{l?.name||"—"}</td>
              <td style={st.td}>{p?.name||"—"} <Tag>{p?.color}</Tag></td>
              <td style={{...st.td,fontFamily:"monospace"}}>{r.quantity}</td>
              <td style={{...st.td,fontFamily:"monospace",color:C.good}}>{fmt(r.wage_earned)}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{num(r.ragzine_used)}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{num(r.mash_used)}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{num(r.daimod_used)}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{num(r.naki_feeta_used)}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{num(r.pipe_used)}</td>
              <td style={st.td}><Danger onClick={()=>del(r.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!production.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No production logged yet.</div>}
    </div>
  );
}

// ─── Advances ────────────────────────────────────────────────
function AdvancesTab({ data, db, refresh }) {
  const { labor=[], advances=[] } = data;
  const [form, setForm] = useState({ date:today(), labor_id:"", amount:0, note:"" });
  const save = () => refresh(async () => {
    if(!form.labor_id) throw new Error("Pick worker");
    const {error} = await db.from("advances").insert([{...form,labor_id:+form.labor_id,amount:+form.amount}]);
    if(error) throw error;
  });
  const del = (id) => refresh(async () => { const {error} = await db.from("advances").delete().eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Advances Paid to Labor" />
      <FormBox title="Add Advance">
        <Grid cols={2}>
          <div><Lbl>Date</Lbl><Inp type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} /></div>
          <div><Lbl>Worker</Lbl>
            <Sel value={form.labor_id} onChange={e=>setForm({...form,labor_id:e.target.value})}>
              <option value="">-- pick worker --</option>
              {labor.map(l=><option key={l.id} value={l.id}>{l.name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Amount (₹)</Lbl><Inp type="number" value={form.amount} onChange={e=>setForm({...form,amount:+e.target.value})} /></div>
          <div><Lbl>Note</Lbl><Inp value={form.note} onChange={e=>setForm({...form,note:e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Advance</Btn>
      </FormBox>
      <Table heads={["Date","Worker","Amount","Note",""]}>
        {advances.slice().reverse().map(r=>{
          const l = labor.find(x=>x.id===r.labor_id);
          return (
            <tr key={r.id}>
              <td style={st.td}>{r.date}</td>
              <td style={st.td}>{l?.name||"—"}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{fmt(r.amount)}</td>
              <td style={st.td}>{r.note}</td>
              <td style={st.td}><Danger onClick={()=>del(r.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!advances.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No advances yet.</div>}
    </div>
  );
}

// ─── Labor Ledger ─────────────────────────────────────────────
function LaborLedgerTab({ data }) {
  const { labor=[], production=[], advances=[], material_issued=[], raw_materials=[] } = data;
  const [sel, setSel] = useState(null);
  const worker = labor.find(l=>l.id===sel);
  const wProd = production.filter(r=>r.labor_id===sel);
  const wAdv = advances.filter(r=>r.labor_id===sel);
  const wIssued = material_issued.filter(r=>r.labor_id===sel);
  const totalWage = +(worker?.opening_balance_payable||0) + wProd.reduce((s,r)=>s++(r.wage_earned||0),0);
  const totalAdv = wAdv.reduce((s,r)=>s++(r.amount||0),0);
  const netPayable = totalWage - totalAdv;

  // Material balance
  const matBalance = raw_materials.map(rm => {
    const issued = wIssued.filter(r=>r.material_id===rm.id).reduce((s,r)=>s++(r.quantity||0),0);
    let consumed = 0;
    wProd.forEach(pr => {
      const isRagzine = rm.material_name === "Ragzine";
      const isMash = rm.material_name === "Mash";
      const isDaimod = rm.material_name === "Daimod";
      const isNaki = rm.material_name === "Naki Feeta";
      const isPipe = rm.material_name === "Pipe";
      const prodP = data.products?.find(p=>p.id===pr.product_id);
      if (isRagzine && prodP?.color === rm.color) consumed += +(pr.ragzine_used||0);
      if (isMash && prodP?.color === rm.color) consumed += +(pr.mash_used||0);
      if (isDaimod) consumed += +(pr.daimod_used||0);
      if (isNaki) consumed += +(pr.naki_feeta_used||0);
      if (isPipe) consumed += +(pr.pipe_used||0);
    });
    return { ...rm, issued, consumed, balance: issued - consumed };
  }).filter(r=>r.issued > 0 || r.balance !== 0);

  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Labor Ledger" />
      <div style={{ display:"flex", gap:8, flexWrap:"wrap" }}>
        {labor.map(l=>(
          <button key={l.id} onClick={()=>setSel(l.id===sel?null:l.id)} style={{ padding:"6px 14px", borderRadius:20, border:`1px solid ${C.border}`, background:sel===l.id?C.accent:C.card, color:sel===l.id?"#fff":C.ink, fontSize:13, fontWeight:600, cursor:"pointer" }}>{l.name}</button>
        ))}
      </div>
      {worker && (
        <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
          <div style={{ display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:12 }}>
            <StatCard title="Wage Earned" value={fmt(totalWage)} green />
            <StatCard title="Advances Given" value={fmt(totalAdv)} red={totalAdv>0} />
            <StatCard title="Net Payable" value={fmt(netPayable)} green={netPayable>0} red={netPayable<0} />
          </div>
          <div style={st.card}>
            <div style={{fontWeight:700,marginBottom:10}}>Material Balance (in hand)</div>
            {matBalance.length ? (
              <table style={{width:"100%",borderCollapse:"collapse"}}>
                <thead><tr>{["Material","Color","Issued","Consumed","Balance"].map(h=><th key={h} style={st.th}>{h}</th>)}</tr></thead>
                <tbody>
                  {matBalance.map(r=>(
                    <tr key={r.id}>
                      <td style={st.td}>{r.material_name}</td>
                      <td style={st.td}><Tag>{r.color}</Tag></td>
                      <td style={{...st.td,fontFamily:"monospace"}}>{num(r.issued)}</td>
                      <td style={{...st.td,fontFamily:"monospace"}}>{num(r.consumed)}</td>
                      <td style={{...st.td,fontFamily:"monospace",color:r.balance<0?C.bad:C.good,fontWeight:700}}>{num(r.balance)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : <div style={{color:C.muted,fontSize:13}}>No material issued to this worker yet.</div>}
          </div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:16}}>
            <div style={st.card}>
              <div style={{fontWeight:700,marginBottom:8}}>Production History</div>
              {wProd.length ? wProd.slice().reverse().map(r=>{
                const p = data.products?.find(x=>x.id===r.product_id);
                return <div key={r.id} style={{display:"flex",justifyContent:"space-between",fontSize:13,padding:"3px 0",borderBottom:`1px solid ${C.border}`}}>
                  <span>{r.date} · {p?.name} {p?.color}</span>
                  <span style={{fontFamily:"monospace"}}>{r.quantity} pcs · {fmt(r.wage_earned)}</span>
                </div>;
              }) : <div style={{color:C.muted,fontSize:13}}>No production yet.</div>}
            </div>
            <div style={st.card}>
              <div style={{fontWeight:700,marginBottom:8}}>Advance History</div>
              {wAdv.length ? wAdv.slice().reverse().map(r=>(
                <div key={r.id} style={{display:"flex",justifyContent:"space-between",fontSize:13,padding:"3px 0",borderBottom:`1px solid ${C.border}`}}>
                  <span>{r.date} {r.note && `· ${r.note}`}</span>
                  <span style={{fontFamily:"monospace",color:C.bad}}>{fmt(r.amount)}</span>
                </div>
              )) : <div style={{color:C.muted,fontSize:13}}>No advances yet.</div>}
            </div>
          </div>
        </div>
      )}
      {!sel && <div style={{color:C.muted,textAlign:"center",padding:32,fontSize:13}}>Select a worker above to see their ledger.</div>}
    </div>
  );
}

// ─── Purchases ────────────────────────────────────────────────
function PurchasesTab({ data, db, refresh }) {
  const { suppliers=[], raw_materials=[], purchases=[] } = data;
  const [form, setForm] = useState({ date:today(), supplier_id:"", material_id:"", quantity:0, rate:0 });
  const save = () => refresh(async () => {
    if(!form.supplier_id||!form.material_id) throw new Error("Pick supplier and material");
    const {error} = await db.from("purchases").insert([{...form,supplier_id:+form.supplier_id,material_id:+form.material_id,quantity:+form.quantity,rate:+form.rate}]);
    if(error) throw error;
  });
  const del = (id) => refresh(async () => { const {error} = await db.from("purchases").delete().eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Raw Material Purchases" />
      <FormBox title="Add Purchase">
        <Grid cols={2}>
          <div><Lbl>Date</Lbl><Inp type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} /></div>
          <div><Lbl>Supplier</Lbl>
            <Sel value={form.supplier_id} onChange={e=>setForm({...form,supplier_id:e.target.value})}>
              <option value="">-- pick supplier --</option>
              {suppliers.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Material</Lbl>
            <Sel value={form.material_id} onChange={e=>setForm({...form,material_id:e.target.value})}>
              <option value="">-- pick material --</option>
              {raw_materials.map(r=><option key={r.id} value={r.id}>{r.display_name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Quantity</Lbl><Inp type="number" value={form.quantity} onChange={e=>setForm({...form,quantity:+e.target.value})} /></div>
          <div><Lbl>Rate (₹ per unit)</Lbl><Inp type="number" value={form.rate} onChange={e=>setForm({...form,rate:+e.target.value})} /></div>
          <div style={{display:"flex",alignItems:"flex-end"}}><div style={{fontSize:13,color:C.muted}}>Total: <b style={{color:C.ink,fontFamily:"monospace"}}>{fmt(+form.quantity * +form.rate)}</b></div></div>
        </Grid>
        <Btn onClick={save}>+ Add Purchase</Btn>
      </FormBox>
      <Table heads={["Date","Supplier","Material","Qty","Rate","Total",""]}>
        {purchases.slice().reverse().map(r=>{
          const s = suppliers.find(x=>x.id===r.supplier_id);
          const m = raw_materials.find(x=>x.id===r.material_id);
          return (
            <tr key={r.id}>
              <td style={st.td}>{r.date}</td>
              <td style={st.td}>{s?.name||"—"}</td>
              <td style={st.td}>{m?.display_name||"—"}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{r.quantity}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{fmt(r.rate)}</td>
              <td style={{...st.td,fontFamily:"monospace",fontWeight:600}}>{fmt(r.total_value)}</td>
              <td style={st.td}><Danger onClick={()=>del(r.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!purchases.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No purchases yet.</div>}
    </div>
  );
}

// ─── Suppliers ────────────────────────────────────────────────
function SuppliersTab({ data, db, refresh }) {
  const { suppliers=[], purchases=[], supplier_payments=[] } = data;
  const [form, setForm] = useState({ name:"", contact:"", opening_balance:0 });
  const save = () => refresh(async () => { if(!form.name) throw new Error("Name required"); const {error} = await db.from("suppliers").insert([form]); if(error) throw error; });
  const del = (id) => refresh(async () => { const {error} = await db.from("suppliers").delete().eq("id",id); if(error) throw error; });
  const upd = (id,f,v) => refresh(async () => { const {error} = await db.from("suppliers").update({[f]:v}).eq("id",id); if(error) throw error; });
  const bal = (s) => +(s.opening_balance||0) + purchases.filter(r=>r.supplier_id===s.id).reduce((a,r)=>a++(r.total_value||0),0) - supplier_payments.filter(r=>r.supplier_id===s.id).reduce((a,r)=>a++(r.amount||0),0);
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Suppliers" />
      <FormBox title="Add Supplier">
        <Grid cols={3}>
          <div><Lbl>Name</Lbl><Inp value={form.name} onChange={e=>setForm({...form,name:e.target.value})} /></div>
          <div><Lbl>Contact</Lbl><Inp value={form.contact} onChange={e=>setForm({...form,contact:e.target.value})} /></div>
          <div><Lbl>Opening Balance (₹)</Lbl><Inp type="number" value={form.opening_balance} onChange={e=>setForm({...form,opening_balance:+e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Supplier</Btn>
      </FormBox>
      <Table heads={["Name","Contact","Opening Bal.","Total Purchased","Total Paid","Balance Payable",""]}>
        {suppliers.map(s=>{
          const totalBought = purchases.filter(r=>r.supplier_id===s.id).reduce((a,r)=>a++(r.total_value||0),0);
          const totalPaid = supplier_payments.filter(r=>r.supplier_id===s.id).reduce((a,r)=>a++(r.amount||0),0);
          const balance = bal(s);
          return (
            <tr key={s.id}>
              <td style={st.td}>{s.name}</td>
              <td style={st.td}>{s.contact}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{fmt(s.opening_balance)}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{fmt(totalBought)}</td>
              <td style={{...st.td,fontFamily:"monospace",color:C.good}}>{fmt(totalPaid)}</td>
              <td style={{...st.td,fontFamily:"monospace",fontWeight:700,color:balance>0?C.bad:C.good}}>{fmt(balance)}</td>
              <td style={st.td}><Danger onClick={()=>del(s.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!suppliers.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No suppliers yet.</div>}
    </div>
  );
}

// ─── Customers ────────────────────────────────────────────────
function CustomersTab({ data, db, refresh }) {
  const { customers=[], sales=[], payments=[] } = data;
  const [form, setForm] = useState({ name:"", contact:"", opening_balance:0 });
  const save = () => refresh(async () => { if(!form.name) throw new Error("Name required"); const {error} = await db.from("customers").insert([form]); if(error) throw error; });
  const del = (id) => refresh(async () => { const {error} = await db.from("customers").delete().eq("id",id); if(error) throw error; });
  const bal = (c) => +(c.opening_balance||0) + sales.filter(r=>r.customer_id===c.id).reduce((a,r)=>a++(r.net_total||0),0) - payments.filter(r=>r.customer_id===c.id).reduce((a,r)=>a++(r.amount||0),0);
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Customers" />
      <FormBox title="Add Customer">
        <Grid cols={3}>
          <div><Lbl>Name</Lbl><Inp value={form.name} onChange={e=>setForm({...form,name:e.target.value})} /></div>
          <div><Lbl>Contact</Lbl><Inp value={form.contact} onChange={e=>setForm({...form,contact:e.target.value})} /></div>
          <div><Lbl>Opening Balance Due (₹)</Lbl><Inp type="number" value={form.opening_balance} onChange={e=>setForm({...form,opening_balance:+e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Customer</Btn>
      </FormBox>
      <Table heads={["Name","Contact","Opening Bal.","Total Sold","Total Received","Balance Due",""]}>
        {customers.map(c=>{
          const totalSold = sales.filter(r=>r.customer_id===c.id).reduce((a,r)=>a++(r.net_total||0),0);
          const totalRecd = payments.filter(r=>r.customer_id===c.id).reduce((a,r)=>a++(r.amount||0),0);
          const balance = bal(c);
          return (
            <tr key={c.id}>
              <td style={st.td}>{c.name}</td>
              <td style={st.td}>{c.contact}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{fmt(c.opening_balance)}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{fmt(totalSold)}</td>
              <td style={{...st.td,fontFamily:"monospace",color:C.good}}>{fmt(totalRecd)}</td>
              <td style={{...st.td,fontFamily:"monospace",fontWeight:700,color:balance>0?C.bad:C.good}}>{fmt(balance)}</td>
              <td style={st.td}><Danger onClick={()=>del(c.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!customers.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No customers yet.</div>}
    </div>
  );
}

// ─── Sales ────────────────────────────────────────────────────
function SalesTab({ data, db, refresh }) {
  const { customers=[], products=[], sales=[], production=[] } = data;
  const [form, setForm] = useState({ date:today(), customer_id:"", product_id:"", quantity:0, rate:0, discount:0 });
  const stock = (pid) => { const p = products.find(x=>x.id===+pid); if(!p) return 0; return +(p.opening_stock||0)+production.filter(r=>r.product_id===+pid).reduce((s,r)=>s++(r.quantity||0),0)-sales.filter(r=>r.product_id===+pid).reduce((s,r)=>s++(r.quantity||0),0); };
  const save = () => refresh(async () => {
    if(!form.customer_id||!form.product_id) throw new Error("Pick customer and product");
    const {error} = await db.from("sales").insert([{...form,customer_id:+form.customer_id,product_id:+form.product_id,quantity:+form.quantity,rate:+form.rate,discount:+form.discount}]);
    if(error) throw error;
  });
  const del = (id) => refresh(async () => { const {error} = await db.from("sales").delete().eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Sales" />
      <FormBox title="New Sale">
        <Grid cols={3}>
          <div><Lbl>Date</Lbl><Inp type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} /></div>
          <div><Lbl>Customer</Lbl>
            <Sel value={form.customer_id} onChange={e=>setForm({...form,customer_id:e.target.value})}>
              <option value="">-- pick customer --</option>
              {customers.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Product</Lbl>
            <Sel value={form.product_id} onChange={e=>{ setForm({...form,product_id:e.target.value,rate:products.find(p=>p.id===+e.target.value)?.selling_price||0}); }}>
              <option value="">-- pick product --</option>
              {products.map(p=><option key={p.id} value={p.id}>{p.name} · {p.color} (stock: {stock(p.id)})</option>)}
            </Sel>
          </div>
          <div><Lbl>Quantity (dozens)</Lbl><Inp type="number" value={form.quantity} onChange={e=>setForm({...form,quantity:+e.target.value})} /></div>
          <div><Lbl>Rate (₹/dozen)</Lbl><Inp type="number" value={form.rate} onChange={e=>setForm({...form,rate:+e.target.value})} /></div>
          <div><Lbl>Discount (₹)</Lbl><Inp type="number" value={form.discount} onChange={e=>setForm({...form,discount:+e.target.value})} /></div>
        </Grid>
        <div style={{fontSize:13,color:C.muted}}>Net Total: <b style={{color:C.ink,fontFamily:"monospace"}}>{fmt(+form.quantity * +form.rate - +form.discount)}</b></div>
        <Btn onClick={save}>+ Save Sale</Btn>
      </FormBox>
      <Table heads={["Date","Customer","Product","Qty","Rate","Discount","Net Total",""]}>
        {sales.slice().reverse().map(r=>{
          const c = customers.find(x=>x.id===r.customer_id);
          const p = products.find(x=>x.id===r.product_id);
          return (
            <tr key={r.id}>
              <td style={st.td}>{r.date}</td>
              <td style={st.td}>{c?.name||"—"}</td>
              <td style={st.td}>{p?.name||"—"} <Tag>{p?.color}</Tag></td>
              <td style={{...st.td,fontFamily:"monospace"}}>{r.quantity}</td>
              <td style={{...st.td,fontFamily:"monospace"}}>{fmt(r.rate)}</td>
              <td style={{...st.td,fontFamily:"monospace",color:+r.discount?C.warn:"inherit"}}>{fmt(r.discount)}</td>
              <td style={{...st.td,fontFamily:"monospace",fontWeight:700}}>{fmt(r.net_total)}</td>
              <td style={st.td}><Danger onClick={()=>del(r.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!sales.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No sales yet.</div>}
    </div>
  );
}

// ─── Payments ────────────────────────────────────────────────
function PaymentsTab({ data, db, refresh }) {
  const { customers=[], payments=[] } = data;
  const [form, setForm] = useState({ date:today(), customer_id:"", amount:0, note:"" });
  const save = () => refresh(async () => {
    if(!form.customer_id) throw new Error("Pick customer");
    const {error} = await db.from("payments").insert([{...form,customer_id:+form.customer_id,amount:+form.amount}]);
    if(error) throw error;
  });
  const del = (id) => refresh(async () => { const {error} = await db.from("payments").delete().eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Payments Received from Customers" />
      <FormBox title="Add Payment">
        <Grid cols={2}>
          <div><Lbl>Date</Lbl><Inp type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} /></div>
          <div><Lbl>Customer</Lbl>
            <Sel value={form.customer_id} onChange={e=>setForm({...form,customer_id:e.target.value})}>
              <option value="">-- pick customer --</option>
              {customers.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Amount Received (₹)</Lbl><Inp type="number" value={form.amount} onChange={e=>setForm({...form,amount:+e.target.value})} /></div>
          <div><Lbl>Note</Lbl><Inp value={form.note} onChange={e=>setForm({...form,note:e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Payment</Btn>
      </FormBox>
      <Table heads={["Date","Customer","Amount","Note",""]}>
        {payments.slice().reverse().map(r=>{
          const c = customers.find(x=>x.id===r.customer_id);
          return (
            <tr key={r.id}>
              <td style={st.td}>{r.date}</td>
              <td style={st.td}>{c?.name||"—"}</td>
              <td style={{...st.td,fontFamily:"monospace",color:C.good,fontWeight:600}}>{fmt(r.amount)}</td>
              <td style={st.td}>{r.note}</td>
              <td style={st.td}><Danger onClick={()=>del(r.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!payments.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No payments received yet.</div>}
    </div>
  );
}

// ─── Supplier Payments ────────────────────────────────────────
function SupplierPaymentsTab({ data, db, refresh }) {
  const { suppliers=[], supplier_payments=[] } = data;
  const [form, setForm] = useState({ date:today(), supplier_id:"", amount:0, note:"" });
  const save = () => refresh(async () => {
    if(!form.supplier_id) throw new Error("Pick supplier");
    const {error} = await db.from("supplier_payments").insert([{...form,supplier_id:+form.supplier_id,amount:+form.amount}]);
    if(error) throw error;
  });
  const del = (id) => refresh(async () => { const {error} = await db.from("supplier_payments").delete().eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Payments Made to Suppliers" />
      <FormBox title="Add Payment">
        <Grid cols={2}>
          <div><Lbl>Date</Lbl><Inp type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} /></div>
          <div><Lbl>Supplier</Lbl>
            <Sel value={form.supplier_id} onChange={e=>setForm({...form,supplier_id:e.target.value})}>
              <option value="">-- pick supplier --</option>
              {suppliers.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}
            </Sel>
          </div>
          <div><Lbl>Amount Paid (₹)</Lbl><Inp type="number" value={form.amount} onChange={e=>setForm({...form,amount:+e.target.value})} /></div>
          <div><Lbl>Note</Lbl><Inp value={form.note} onChange={e=>setForm({...form,note:e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Payment</Btn>
      </FormBox>
      <Table heads={["Date","Supplier","Amount","Note",""]}>
        {supplier_payments.slice().reverse().map(r=>{
          const s = suppliers.find(x=>x.id===r.supplier_id);
          return (
            <tr key={r.id}>
              <td style={st.td}>{r.date}</td>
              <td style={st.td}>{s?.name||"—"}</td>
              <td style={{...st.td,fontFamily:"monospace",color:C.bad,fontWeight:600}}>{fmt(r.amount)}</td>
              <td style={st.td}>{r.note}</td>
              <td style={st.td}><Danger onClick={()=>del(r.id)}>✕</Danger></td>
            </tr>
          );
        })}
      </Table>
      {!supplier_payments.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No supplier payments yet.</div>}
    </div>
  );
}

// ─── Expenses ────────────────────────────────────────────────
function ExpensesTab({ data, db, refresh }) {
  const { expenses=[] } = data;
  const CATS = ["Rent","Electricity","Transport","Maintenance","Marketing","Misc"];
  const [form, setForm] = useState({ date:today(), category:"Rent", amount:0, note:"" });
  const save = () => refresh(async () => { const {error} = await db.from("expenses").insert([{...form,amount:+form.amount}]); if(error) throw error; });
  const del = (id) => refresh(async () => { const {error} = await db.from("expenses").delete().eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <SectionHead title="Expenses" />
      <FormBox title="Add Expense">
        <Grid cols={2}>
          <div><Lbl>Date</Lbl><Inp type="date" value={form.date} onChange={e=>setForm({...form,date:e.target.value})} /></div>
          <div><Lbl>Category</Lbl><Sel value={form.category} onChange={e=>setForm({...form,category:e.target.value})}>{CATS.map(c=><option key={c}>{c}</option>)}</Sel></div>
          <div><Lbl>Amount (₹)</Lbl><Inp type="number" value={form.amount} onChange={e=>setForm({...form,amount:+e.target.value})} /></div>
          <div><Lbl>Note</Lbl><Inp value={form.note} onChange={e=>setForm({...form,note:e.target.value})} /></div>
        </Grid>
        <Btn onClick={save}>+ Add Expense</Btn>
      </FormBox>
      <Table heads={["Date","Category","Amount","Note",""]}>
        {expenses.slice().reverse().map(e=>(
          <tr key={e.id}>
            <td style={st.td}>{e.date}</td>
            <td style={st.td}>{e.category}</td>
            <td style={{...st.td,fontFamily:"monospace"}}>{fmt(e.amount)}</td>
            <td style={st.td}>{e.note}</td>
            <td style={st.td}><Danger onClick={()=>del(e.id)}>✕</Danger></td>
          </tr>
        ))}
      </Table>
      {!expenses.length && <div style={{color:C.muted,textAlign:"center",padding:24,fontSize:13}}>No expenses yet.</div>}
    </div>
  );
}

// ─── Reports ─────────────────────────────────────────────────
function ReportsTab({ data }) {
  const [period, setPeriod] = useState(29);
  const PERIODS = [{ label:"Daily (today)", days:0 },{ label:"Weekly (7d)", days:6 },{ label:"Fortnightly (15d)", days:14 },{ label:"Monthly (30d)", days:29 },{ label:"Annual (365d)", days:364 }];
  const { sales=[], expenses=[], production=[], purchases=[], raw_materials=[], products=[], payments=[], supplier_payments=[], suppliers=[], customers=[], advances=[] } = data;
  const pSales = sales.filter(r=>inRange(r.date,period));
  const pExp = expenses.filter(r=>inRange(r.date,period));
  const pProd = production.filter(r=>inRange(r.date,period));
  const revenue = pSales.reduce((s,r)=>s++(r.net_total||0),0);
  const discounts = pSales.reduce((s,r)=>s++(r.discount||0),0);
  const overheads = pExp.reduce((s,r)=>s++(r.amount||0),0) + discounts;
  const wages = pProd.reduce((s,r)=>s++(r.wage_earned||0),0);
  const rawVal = raw_materials.reduce((s,r)=>s++(r.opening_stock||0)*+(r.cost_per_unit||0),0);
  const custBal = customers.reduce((s,c)=>{ const sold=sales.filter(r=>r.customer_id===c.id).reduce((a,r)=>a++(r.net_total||0),0); const paid=payments.filter(r=>r.customer_id===c.id).reduce((a,r)=>a++(r.amount||0),0); return s++(c.opening_balance||0)+sold-paid; },0);
  const suppBal = suppliers.reduce((s,sup)=>{ const bought=purchases.filter(r=>r.supplier_id===sup.id).reduce((a,r)=>a++(r.total_value||0),0); const paid=supplier_payments.filter(r=>r.supplier_id===sup.id).reduce((a,r)=>a++(r.amount||0),0); return s++(sup.opening_balance||0)+bought-paid; },0);
  const nwc = rawVal + custBal - suppBal + +(data.settings?.cash_in_hand||0);
  const grossProfit = revenue - wages;
  const netProfit = grossProfit - overheads;
  const margin = revenue ? (netProfit/revenue*100).toFixed(1) : "—";
  const roi = nwc ? (netProfit/nwc*100).toFixed(2) : "—";
  const units = pProd.reduce((s,r)=>s++(r.quantity||0),0);
  const unitsSold = pSales.reduce((s,r)=>s++(r.quantity||0),0);
  const invTurn = rawVal ? (wages/rawVal).toFixed(2) : "—";
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:20 }}>
      <SectionHead title="Reports" action={
        <div style={{display:"flex",gap:6}}>
          {PERIODS.map(p=>(
            <button key={p.days} onClick={()=>setPeriod(p.days)} style={{ padding:"5px 12px", borderRadius:20, border:`1px solid ${C.border}`, background:period===p.days?C.accent:C.card, color:period===p.days?"#fff":C.muted, fontSize:12, fontWeight:600, cursor:"pointer" }}>{p.label}</button>
          ))}
        </div>
      } />
      <Grid cols={2}>
        <StatCard title="Net Profit" value={fmt(netProfit)} green={netProfit>0} red={netProfit<0} sub={`Margin ${margin}%`} />
        <StatCard title="Revenue" value={fmt(revenue)} sub={`${pSales.length} sales · ${unitsSold} dozens`} />
        <StatCard title="Wages Paid" value={fmt(wages)} sub={`${units} dozens produced`} />
        <StatCard title="Overheads + Discounts" value={fmt(overheads)} sub={`Discounts: ${fmt(discounts)}`} />
        <StatCard title="Net Working Capital" value={fmt(nwc)} green={nwc>0} sub="Stock + Receivables − Payables + Cash" />
        <StatCard title="ROI" value={roi === "—" ? "—" : roi+"%"} green={+roi>0} sub="Net Profit ÷ Net Working Capital" />
      </Grid>
      <div style={{ ...st.card }}>
        <div style={{ fontWeight:700, fontSize:14, marginBottom:12 }}>Profit & Loss</div>
        <table style={{ width:"100%", borderCollapse:"collapse" }}>
          <tbody>
            <Row label="Sales Revenue (net of discounts)" val={fmt(revenue)} />
            <Row label="Wage Cost (labor)" val={`− ${fmt(wages)}`} />
            <Row label="Gross Profit" val={fmt(grossProfit)} bold green={grossProfit>0} red={grossProfit<0} />
            <Row label="Other Overheads (expenses + discounts)" val={`− ${fmt(overheads)}`} />
            <Row label="Net Profit" val={fmt(netProfit)} bold green={netProfit>0} red={netProfit<0} />
            <Row label="Profit Margin %" val={margin === "—" ? "—" : margin+"%"} sub />
          </tbody>
        </table>
      </div>
      <Grid cols={2}>
        <div style={st.card}>
          <div style={{fontWeight:700,marginBottom:10}}>Customer Balances</div>
          {customers.map(c=>{
            const sold=sales.filter(r=>r.customer_id===c.id).reduce((a,r)=>a++(r.net_total||0),0);
            const paid=payments.filter(r=>r.customer_id===c.id).reduce((a,r)=>a++(r.amount||0),0);
            const bal=+(c.opening_balance||0)+sold-paid;
            return <div key={c.id} style={{display:"flex",justifyContent:"space-between",fontSize:13,padding:"4px 0",borderBottom:`1px solid ${C.border}`}}>
              <span>{c.name}</span><span style={{fontFamily:"monospace",color:bal>0?C.bad:C.good,fontWeight:600}}>{fmt(bal)}</span>
            </div>;
          })}
          {!customers.length && <div style={{color:C.muted,fontSize:13}}>No customers.</div>}
        </div>
        <div style={st.card}>
          <div style={{fontWeight:700,marginBottom:10}}>Supplier Balances</div>
          {suppliers.map(s=>{
            const bought=purchases.filter(r=>r.supplier_id===s.id).reduce((a,r)=>a++(r.total_value||0),0);
            const paid2=supplier_payments.filter(r=>r.supplier_id===s.id).reduce((a,r)=>a++(r.amount||0),0);
            const bal=+(s.opening_balance||0)+bought-paid2;
            return <div key={s.id} style={{display:"flex",justifyContent:"space-between",fontSize:13,padding:"4px 0",borderBottom:`1px solid ${C.border}`}}>
              <span>{s.name}</span><span style={{fontFamily:"monospace",color:bal>0?C.bad:C.good,fontWeight:600}}>{fmt(bal)}</span>
            </div>;
          })}
          {!suppliers.length && <div style={{color:C.muted,fontSize:13}}>No suppliers.</div>}
        </div>
      </Grid>
    </div>
  );
}

// ─── Settings ────────────────────────────────────────────────
function SettingsTab({ data, db, refresh }) {
  const { categories=[] } = data;
  const [biz, setBiz] = useState(data.settings?.business_name || "");
  const [cash, setCash] = useState(data.settings?.cash_in_hand || 0);
  const saveSett = () => refresh(async () => {
    const {error} = await db.from("settings").update({ business_name: biz, cash_in_hand: +cash }).eq("id",1);
    if(error) throw error;
  });
  const updCat = (id,f,v) => refresh(async () => { const {error} = await db.from("categories").update({[f]:+v}).eq("id",id); if(error) throw error; });
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:20 }}>
      <SectionHead title="Settings" />
      <FormBox title="Business">
        <div><Lbl>Business Name</Lbl><Inp value={biz} onChange={e=>setBiz(e.target.value)} /></div>
        <div><Lbl>Cash in Hand (₹)</Lbl><Inp type="number" value={cash} onChange={e=>setCash(e.target.value)} /></div>
        <Btn onClick={saveSett}>Save</Btn>
      </FormBox>
      <div style={st.card}>
        <div style={{fontWeight:700,fontSize:14,marginBottom:12}}>Categories — Material Averages & Wage Rate</div>
        <div style={{fontSize:12,color:C.muted,marginBottom:12}}>These apply to all products within each category. Ragzine/Mash averages are per piece, Daimod/Naki Feeta/Pipe are per piece too. Wage rate is per piece (updated per worker in the Labor tab).</div>
        <Table heads={["Category","Ragzine/pc","Mash/pc","Daimod/pc","Naki Feeta/pc","Pipe/pc","Wage Rate/pc"]}>
          {categories.map(c=>(
            <tr key={c.id}>
              <td style={{...st.td,fontWeight:700}}>{c.name}</td>
              {["ragzine_per_pc","mash_per_pc","daimod_per_pc","naki_feeta_per_pc","pipe_per_pc","wage_rate"].map(f=>(
                <td key={f} style={st.td}><Inp type="number" defaultValue={c[f]} onBlur={e=>updCat(c.id,f,e.target.value)} style={{...st.input,width:80}} /></td>
              ))}
            </tr>
          ))}
        </Table>
      </div>
    </div>
  );
}
