"use client";

import { useEffect, useState } from "react";

export default function Home() {
  const [data, setData] = useState<{ message: string; timestamp: string } | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/ping`)
      .then((res) => res.json())
      .then(setData)
      .catch((err) => setError(err.message));
  }, []);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-zinc-50 dark:bg-black p-8">
      <h1 className="text-2xl font-bold mb-4">AS-Starter</h1>
      {error && <p className="text-red-500">Error: {error}</p>}
      {data && (
        <div className="text-center">
          <p className="text-lg">Backend says: <strong>{data.message}</strong></p>
          <p className="text-sm text-zinc-500">{new Date(data.timestamp).toLocaleString()}</p>
        </div>
      )}
      {!data && !error && <p className="text-zinc-400">Connecting to backend...</p>}
    </div>
  );
}
