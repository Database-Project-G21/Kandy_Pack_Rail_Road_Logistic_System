"use client";
import {useEffect,useState,useRef} from "react";
import {useRouter} from "next/navigation";
import {readJson,errorText} from "../lib/api-response";
import {Notice} from "../components/Feedback";
const API=process.env.NEXT_PUBLIC_API_URL||"http://localhost:8081";
type Options={trains:{train_id:string;size:number}[];stores:{store_id:string;city_name:string}[]};
export default function Trips(){const router=useRouter();const [options,setOptions]=useState<Options>({trains:[],stores:[]});const [error,setError]=useState("");const [message,setMessage]=useState("");const [busy,setBusy]=useState(false);const lock=useRef(false);const [attempt,setAttempt]=useState(0);
 useEffect(()=>{if(!["ADMIN","DISPATCHER"].includes(localStorage.getItem("role")||"")){router.replace("/login");return;}
 const c=new AbortController();fetch(`${API}/api/trains/options`,{headers:{Authorization:`Bearer ${localStorage.getItem("token")}`},signal:c.signal}).then(readJson<Options>).then(setOptions).catch(e=>{if(!c.signal.aborted)setError(errorText(e));});return()=>c.abort();},[router,attempt]);
 async function save(e:React.FormEvent<HTMLFormElement>){e.preventDefault();if(lock.current)return;lock.current=true;setBusy(true);setError("");setMessage("");const form=e.currentTarget;const f=new FormData(form);
 try{const r=await fetch(`${API}/api/trains`,{method:"POST",headers:{"Content-Type":"application/json",Authorization:`Bearer ${localStorage.getItem("token")}`},body:JSON.stringify({trainId:f.get("train"),storeId:f.get("store"),departure:f.get("departure"),arrival:f.get("arrival"),capacity:Number(f.get("capacity"))})}).then(readJson<{tripId:string}>);setMessage(`Trip ${r.tripId} created. Customers can now reserve its capacity when ordering.`);form.reset();}catch(e){setError(errorText(e));}finally{lock.current=false;setBusy(false);}}
 const cls="block w-full border rounded p-2 mt-1";
 return <div className="workspace-shell"><section className="workspace-panel"><h1 className="text-2xl font-bold">Add a future train trip</h1><p className="my-3">Use the actual railway cargo allocation. All times are Sri Lanka local time. Existing orders and old trips stay unchanged.</p>
 {error&&<Notice kind="error">{error}<button className="secondary-button ml-3" onClick={()=>{setError("");setAttempt(n=>n+1);}}>Reload options</button></Notice>}{message&&<Notice kind="success">{message}</Notice>}
 <form onSubmit={save}><fieldset disabled={busy} className="grid md:grid-cols-2 gap-4 my-5">
 <label>Train<select name="train" className={cls} required><option value="">Select train</option>{options.trains.map(t=><option key={t.train_id} value={t.train_id}>{t.train_id} — size {t.size}</option>)}</select></label>
 <label>Destination store<select name="store" className={cls} required><option value="">Select store</option>{options.stores.map(s=><option key={s.store_id} value={s.store_id}>{s.city_name} — {s.store_id}</option>)}</select></label>
 <label>Departure<input name="departure" className={cls} required type="datetime-local"/></label><label>Arrival<input name="arrival" className={cls} required type="datetime-local"/></label>
 <label>Allocated cargo capacity<input name="capacity" className={cls} required type="number" min="0.01" step="0.01"/></label>
 <button className="primary-button self-end" disabled={busy||options.trains.length===0}>{busy?"Saving…":"Create trip"}</button>
 </fieldset></form></section></div>;
}
