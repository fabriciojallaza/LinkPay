import { Wallet, Users, Calendar } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import {NotAvailable} from "@/components/ui/not-available";

interface DashboardProps {
  companies: Company[];
  payments: Payment[];
  employees?: Employee[];
  usdcBalance?: string;
  currentCompanyId?: number;
  onNavigateToRegister: () => void;
}

interface Employee {
  id: string;
  name: string;
  walletAddress: string;
}

interface Company {
  id: string;
  name: string;
  walletAddress: string;
  registrationDate: string;
}

interface Payment {
  id: string;
  companyId: string;
  employeeName: string;
  employeeWallet: string;
  amount: number;
  scheduledDate: string;
  status: 'pending' | 'completed' | 'scheduled';
  timestamp?: number;
}

export function Dashboard({ companies, payments, employees = [], usdcBalance = '0', currentCompanyId, onNavigateToRegister }: DashboardProps) {
  const completedPayments = payments.filter(p => p.status === 'completed').length;
  const totalPaid = payments.filter(p => p.status === 'completed').reduce((sum, p) => sum + p.amount, 0);

  const myEmployees = employees?.length || 0;
  let companyName = 'Dashboard';
  const hasNoCompanies = companies.length === 0 || !currentCompanyId || currentCompanyId <= 0;
  
  if(!hasNoCompanies && currentCompanyId && currentCompanyId > 0){
    companyName = companies.filter(c => c.id === String(currentCompanyId))[0]?.name;
  }

  const recentPayments = payments.slice(0, 5);


  return (
    <div className="space-y-6 relative">
      {hasNoCompanies && (
          <div className="absolute inset-0 bg-white/80 backdrop-blur-sm z-40 rounded-lg" />
      )}
      <NotAvailable hasNoCompanies={hasNoCompanies} onNavigateToRegister={onNavigateToRegister} />

      {/* Main content */}
      <div className={hasNoCompanies ? 'pointer-events-none select-none' : ''}>
      <div>
        <h2>{companyName}</h2>
        <p className="text-gray-500">
          {hasNoCompanies ? 'Register your company to get started' : 'Overview of your company payment system'}
        </p>
      </div>

      {hasNoCompanies ? (
        <Card>
          <CardContent className="py-12">
            <div className="text-center">
              <Wallet className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500">No company registered</p>
              <p className="text-sm text-gray-400 mt-1">Connect your wallet and register your company to start managing payments</p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm">My Employees</CardTitle>
            <Users className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{myEmployees}</div>
            <p className="text-xs text-gray-500 mt-1">Active employees</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm">USDC Balance</CardTitle>
            <Wallet className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{parseFloat(usdcBalance).toLocaleString()} USDC</div>
            <p className="text-xs text-gray-500 mt-1">Available for payments</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm">Total Payments</CardTitle>
            <Calendar className="h-4 w-4 text-gray-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{completedPayments}</div>
            <p className="text-xs text-gray-500 mt-1">Successfully completed</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm">Total Paid</CardTitle>
            <Wallet className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">{totalPaid.toLocaleString()} USDC</div>
            <p className="text-xs text-gray-500 mt-1">Lifetime payments</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Recent Payments</CardTitle>
        </CardHeader>
        <CardContent>
          {recentPayments.length === 0 ? (
            <p className="text-gray-500 text-center py-8">No payments scheduled yet</p>
          ) : (
            <div className="space-y-4">
              {recentPayments.map((payment) => {
                const company = companies.find(c => c.id === payment.companyId);

                // Format date and time
                const formatDateTime = (timestamp?: number, dateString?: string) => {
                  if (timestamp) {
                    const date = new Date(timestamp * 1000);
                    const dateStr = date.toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric'
                    });
                    const timeStr = date.toLocaleTimeString('en-US', {
                      hour: '2-digit',
                      minute: '2-digit'
                    });
                    return { date: dateStr, time: timeStr };
                  }
                  return { date: dateString || 'N/A', time: null };
                };

                const { date, time } = formatDateTime(payment.timestamp, payment.scheduledDate);

                return (
                  <div key={payment.id} className="flex items-center justify-between border-b pb-3 last:border-0">
                    <div>
                      <p className="font-medium">{payment.employeeName}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold">{payment.amount.toLocaleString()} USDC</p>
                      <p className="text-sm text-gray-500">{date}</p>
                      {time && <p className="text-xs text-gray-400">{time}</p>}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
      </>
    )}
      </div>
    </div>
  );
}
