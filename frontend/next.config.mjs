const railsBaseUrl = process.env.RAILS_API_BASE_URL ?? "http://localhost:3000";

/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${railsBaseUrl}/api/:path*`
      },
      {
        source: "/logout",
        destination: `${railsBaseUrl}/logout`
      }
    ];
  }
};

export default nextConfig;
