import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from './supabase-config.js';
const $=id=>document.getElementById(id);
const status=message=>{$('status').textContent=message};
const configured=/^https:\/\/[a-z0-9-]+\.supabase\.co$/.test(SUPABASE_URL)&&/^(sb_publishable_|eyJ)/.test(SUPABASE_PUBLISHABLE_KEY);
let supabase=null,activeUser=null;
if(!configured){status('Member registration is not active. A dedicated Island Hearts Supabase project must be configured and security-tested before real accounts can be created.');}
else {
  try {
    // Public publishable key only. Never embed a secret or service_role key.
    const {createClient}=await import('https://esm.sh/@supabase/supabase-js@2.57.0');
    supabase=createClient(SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY);
    const {data:{user},error}=await supabase.auth.getUser();
    if(error)status(error.message);else await showUser(user);
    supabase.auth.onAuthStateChange((_event,session)=>{queueMicrotask(()=>showUser(session?.user||null))});
  }catch(e){status('Unable to load the secure authentication client. Registration is unavailable.')}
}
async function showUser(user){
 activeUser=user;
 $('guest').classList.toggle('hidden',!!user);
 $('member').classList.toggle('hidden',!user);
 if(!user){status('Sign in or create an account to continue.');return}
 $('memberEmail').textContent='Signed in as '+user.email;
 const {data,error}=await supabase.from('ih_profiles').select('display_name,age,gender,city,bio,approval_status').eq('user_id',user.id).maybeSingle();
 if(error){status('Profile status could not be loaded. Please contact support.');return}
 if(data){$('profile').classList.add('hidden');status('Your profile is '+data.approval_status+'. You cannot edit it until a secure profile-editing workflow is available.')}
 else{ $('profile').classList.remove('hidden');status('Account active. Complete your profile to request moderator approval.')}
}
$('signup').addEventListener('submit',async e=>{
 e.preventDefault();if(!supabase)return;
 const email=$('email').value.trim(),password=$('password').value;
 if(password.length<12||!$('ageConsent').checked||!$('privacyConsent').checked)return status('Please complete the adult-consent checks and use a password of at least 12 characters.');
 const button=e.submitter;button.disabled=true;
 try{const {error}=await supabase.auth.signUp({email,password,options:{emailRedirectTo:location.origin+location.pathname}});
 status(error?'Registration failed: '+error.message:'Registration submitted. Check your email to confirm your address before logging in.');if(!error)$('signup').reset();}
 finally{button.disabled=false}
});
$('login').addEventListener('submit',async e=>{
 e.preventDefault();if(!supabase)return;
 const button=e.submitter;button.disabled=true;
 try{const {error}=await supabase.auth.signInWithPassword({email:$('loginEmail').value.trim(),password:$('loginPassword').value});status(error?'Login failed: '+error.message:'Signed in.');}
 finally{button.disabled=false}
});
$('resendConfirmation').addEventListener('click',async()=>{
 if(!supabase)return;
 const email=$('loginEmail').value.trim();
 if(!email || !/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email)){status('Enter your registered email address in the login form first.');return}
 const button=$('resendConfirmation');button.disabled=true;
 try{
  const {error}=await supabase.auth.resend({type:'signup',email,options:{emailRedirectTo:location.origin+location.pathname}});
  status(error?'Could not resend confirmation: '+error.message:'If the address is eligible, a fresh confirmation email has been requested. Check Inbox and Spam. Only use the newest confirmation link.');
 }catch(_e){status('Unable to request a confirmation email. Please try again.')}
 finally{button.disabled=false}
});
$('logout').addEventListener('click',async()=>{if(supabase){await supabase.auth.signOut();status('Signed out.')}});
$('profile').addEventListener('submit',async e=>{
 e.preventDefault();if(!supabase||!activeUser)return;
 const age=Number($('age').value);if(!Number.isInteger(age)||age<18||age>110)return status('Only adults aged 18+ may register.');
 const payload={user_id:activeUser.id,display_name:$('displayName').value.trim(),age,gender:$('gender').value,city:$('city').value.trim(),bio:$('bio').value.trim()};
 const button=e.submitter;button.disabled=true;
 try{const {error}=await supabase.from('ih_profiles').insert(payload);if(error)status('Profile submission failed: '+error.message);else{status('Profile submitted for moderation. It is not publicly visible yet.');await showUser(activeUser);}}
 finally{button.disabled=false}
});
$('searchButton').addEventListener('click',async()=>{
 if(!supabase||!activeUser)return;const root=$('results');root.replaceChildren();
 let query=supabase.from('ih_profiles').select('user_id,display_name,age,gender,city,bio').eq('approval_status','approved').eq('is_visible',true).neq('user_id',activeUser.id).limit(30);
 if($('searchGender').value)query=query.eq('gender',$('searchGender').value);
 if($('searchCity').value.trim())query=query.ilike('city',$('searchCity').value.trim().replace(/[%_,]/g,'')+'%');
 const {data,error}=await query;if(error)return status('Search failed. Please try again.');if(!data?.length)return status('No approved profiles match your search.');
 for(const p of data){const article=document.createElement('article');article.className='person';const name=document.createElement('strong');name.textContent=p.display_name+', '+p.age;const city=document.createElement('p');city.textContent=p.city+' · '+p.gender;const bio=document.createElement('p');bio.textContent=p.bio||'Seeking a meaningful connection';article.append(name,city,bio);const request=document.createElement('button');request.textContent='Request introduction';request.addEventListener('click',async()=>{request.disabled=true;const {error}=await supabase.from('ih_connections').insert({requester:activeUser.id,recipient:p.user_id});status(error?'Could not send request: '+error.message:'Introduction request sent. Messaging is available only after acceptance.');});article.append(request);root.append(article);}
 status('Showing '+data.length+' approved profile(s).');
});
