"use client";

import Link from "next/link";

export const Logo: React.FC<{ className?: string }> = ({ className }) => {
  return (
    <Link href="/" className={`flex items-center gap-3 group ${className || ""}`}>
      <div className="relative w-10 h-10">
        {/* Outer Glow on Hover */}
        <div className="absolute -inset-2 bg-green-500/30 rounded-full blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>

        <svg
          viewBox="0 0 40 40"
          fill="none"
          className="w-full h-full transform group-hover:scale-105 transition-transform duration-500 ease-out"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient
              id="ballGradient"
              x1="4"
              y1="4"
              x2="36"
              y2="36"
              gradientUnits="userSpaceOnUse"
            >
              <stop stopColor="#22c55e" />
              <stop offset="1" stopColor="#15803d" />
            </linearGradient>
          </defs>

          {/* Ball Body - Circle */}
          <circle cx="20" cy="20" r="18" fill="url(#ballGradient)" className="shadow-lg" />

          {/* Football Pattern: Stylized Panels */}
          <path
            d="M20 10L29.5 16.9V28.1L20 35L10.5 28.1V16.9L20 10Z"
            fill="white"
            fillOpacity="0.15"
          />

          {/* Connecting lines suggesting spherical shape */}
          <path
            d="M20 10V2"
            stroke="white"
            strokeWidth="1.5"
            strokeOpacity="0.2"
            strokeLinecap="round"
          />
          <path
            d="M29.5 16.9L36 12"
            stroke="white"
            strokeWidth="1.5"
            strokeOpacity="0.2"
            strokeLinecap="round"
          />
          <path
            d="M29.5 28.1L36 32"
            stroke="white"
            strokeWidth="1.5"
            strokeOpacity="0.2"
            strokeLinecap="round"
          />
          <path
            d="M10.5 28.1L4 32"
            stroke="white"
            strokeWidth="1.5"
            strokeOpacity="0.2"
            strokeLinecap="round"
          />
          <path
            d="M10.5 16.9L4 12"
            stroke="white"
            strokeWidth="1.5"
            strokeOpacity="0.2"
            strokeLinecap="round"
          />

          {/* Energy Bolt */}
          <path
            d="M23 6L13 20H19.5L16.5 34L27.5 18H21L23 6Z"
            fill="white"
            className="drop-shadow-[0_2px_4px_rgba(0,0,0,0.2)] group-hover:-rotate-12 origin-center transition-transform duration-300 ease-in-out"
          />
        </svg>
      </div>

      <div className="flex flex-col justify-center -space-y-1 select-none">
        <span className="font-extrabold text-2xl tracking-tight text-slate-900 dark:text-white leading-none font-sans transition-colors">
          Fur<span className="text-green-500">sal</span>
        </span>
        <div className="overflow-hidden h-3 relative">
          <span className="absolute top-0 left-0 text-[0.65rem] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-[0.2em] transform translate-y-full group-hover:translate-y-0 transition-transform duration-300 delay-75">
            Nepal
          </span>
        </div>
      </div>
    </Link>
  );
};
