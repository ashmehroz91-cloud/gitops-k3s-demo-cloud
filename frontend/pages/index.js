export async function getServerSideProps() {
  const BACKEND_URL = process.env.BACKEND_URL || 'http://backend.default.svc.cluster.local:8080';
  let backendText = '';
  try {
    const res = await fetch(`${BACKEND_URL}/health`);
    backendText = await res.text();
  } catch (err) {
    backendText = `error: ${err.message}`;
  }
  return { props: { backendText } };
}

export default function Page({ backendText }) {
  return (
    <main style={{ padding: 24, fontFamily: 'system-ui, sans-serif' }}>
      <h1>Next.js Frontend</h1>
      <p>Backend response: <strong>{backendText}</strong></p>
    </main>
  );
}
