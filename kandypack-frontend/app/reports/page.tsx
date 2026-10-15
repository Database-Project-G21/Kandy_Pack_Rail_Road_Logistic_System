"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { readJson, errorText } from "../lib/api-response";
import { Notice, LoadingState } from "../components/Feedback";
const API=process.env.NEXT_PUBLIC_API_URL || "http://localhost:8081";
type Row=Record<string,string|number|null>;
const reports:Record<string,string>={quarterly:"Quarterly sales", "top-items":"Most ordered products", "city-routes":"City and route sales", "crew-hours":"Driver and assistant hours", "truck-usage":"Monthly truck usage", history:"Customer delivery history"};
export default function Reports(){
 const router=useRouter();const [report,setReport]=useState("quarterly");
 const [year,setYear]=useState(new Date().getFullYear());const [quarter,setQuarter]=useState(Math.floor(new Date().getMonth()/3)+1);
 const [month,setMonth]=useState(new Date().getMonth()+1);const [week,setWeek]=useState(new Date().toISOString().slice(0,10));
 const [customer,setCustomer]=useState("");const [rows,setRows]=useState<Row[]>([]);
 const [busy,setBusy]=useState(false);const [error,setError]=useState("");const [loaded,setLoaded]=useState(false);
 useEffect(()=>{if(!["ADMIN","DISPATCHER"].includes(localStorage.getItem("role")||""))router.replace("/login");},[router]);
 async function load(e:React.FormEvent){e.preventDefault();setBusy(true);setError("");setLoaded(false);setRows([]);
  try{const query=new URLSearchParams({
    year:String(year),quarter:String(quarter),month:String(month),week,customerId:customer});
   const data=await fetch(`${API}/api/reports/${report}?${query}`,{headers:{Authorization:`Bearer ${localStorage.getItem("token")}`}}).then(readJson<Row[]>);
   if(!Array.isArray(data))throw new Error("Unexpected report response");setRows(data);setLoaded(true);
  }catch(e){setError(errorText(e));}finally{setBusy(false);}}
 function download(){const cols=Object.keys(rows[0]||{});const cell=(v:unknown)=>{let s=String(v??"");if(/^[\s]*[=+@-]/.test(s))s="'"+s;return '"'+s.replaceAll('"','""')+'"';};
  const csv=[cols,...rows.map(r=>cols.map(c=>r[c]))].map(r=>r.map(cell).join(",")).join("\r\n");
  const url=URL.createObjectURL(new Blob(["\ufeff",csv],{type:"text/csv;charset=utf-8"}));const a=document.createElement("a");a.href=url;a.download=`kandypack-${report}.csv`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
 return <div className="workspace-shell"><section className="workspace-panel"><h1 className="text-2xl font-bold">Management reports</h1>
 <p className="my-3 text-sm text-slate-600">Sales include all non-cancelled orders at the price recorded when ordered. Crew hours are scheduled hours, not attendance. All schedules use Sri Lanka local time.</p>
 <form onSubmit={load} className="flex flex-wrap gap-4 items-end my-5">
 <label>Report<select className="block border rounded p-2" value={report} disabled={busy} onChange={e=>{setReport(e.target.value);setLoaded(false);setRows([]);}}>{Object.entries(reports).map(([k,v])=><option key={k} value={k}>{v}</option>)}</select></label>
 {["quarterly","top-items","truck-usage"].includes(report)&&<label>Year<input className="block border rounded p-2 w-28" type="number" min="2000" max="2100" required value={year} disabled={busy} onChange={e=>{setYear(Number(e.target.value));setLoaded(false);setRows([]);}}/></label>}
 {["quarterly","top-items"].includes(report)&&<label>Quarter<select className="block border rounded p-2" value={quarter} disabled={busy} onChange={e=>{setQuarter(Number(e.target.value));setLoaded(false);setRows([]);}}>{[1,2,3,4].map(q=><option key={q}>{q}</option>)}</select></label>}
 {report==="truck-usage"&&<label>Month<input className="block border rounded p-2 w-24" type="number" min="1" max="12" required value={month} disabled={busy} onChange={e=>{setMonth(Number(e.target.value));setLoaded(false);setRows([]);}}/></label>}
 {report==="crew-hours"&&<label>Date in the week<input className="block border rounded p-2" type="date" required value={week} disabled={busy} onChange={e=>{setWeek(e.target.value);setLoaded(false);setRows([]);}}/></label>}
 {report==="history"&&<label>Customer ID (optional)<input className="block border rounded p-2" value={customer} disabled={busy} onChange={e=>{setCustomer(e.target.value);setLoaded(false);setRows([]);}}/></label>}
 <button className="primary-button" disabled={busy}>{busy?"Loading…":"Show report"}</button></form>
 {busy&&<LoadingState>Loading report…</LoadingState>}{error&&<Notice kind="error">{error}</Notice>}
 {loaded&&rows.length===0&&<Notice kind="info">No records for this selection.</Notice>}
 {loaded&&rows.length>0&&<><button className="secondary-button mb-4" onClick={download}>Download CSV</button><div className="overflow-x-auto"><table className="w-full text-sm text-left"><thead><tr>{Object.keys(rows[0]).map(c=><th className="p-3 border-b capitalize" key={c}>{c.replaceAll("_"," ")}</th>)}</tr></thead><tbody>{rows.map((r,i)=><tr key={i}>{Object.entries(r).map(([c,v])=><td className="p-3 border-b" key={c}>{v==null?"Not recorded":String(v)}</td>)}</tr>)}</tbody></table></div></>}
 </section></div>;
}
