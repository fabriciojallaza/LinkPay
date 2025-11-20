import { Building2 } from 'lucide-react';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from './dialog';
import { Button } from './button';

interface NotAvailableProps {
    hasNoCompanies: boolean;
    onNavigateToRegister: () => void;
}


export function NotAvailable({ hasNoCompanies, onNavigateToRegister }: NotAvailableProps) {



    const handleRegisterClick = () => {
        if (onNavigateToRegister) {
            onNavigateToRegister();
        }
    };

    return (
        <div className="space-y-6 relative">




            {/* Dialog for no companies */}
            <Dialog open={hasNoCompanies} onOpenChange={() => {}}>
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <div className="flex items-center justify-center w-12 h-12 mx-auto mb-4 bg-blue-100 rounded-full">
                            <Building2 className="h-6 w-6 text-blue-600" />
                        </div>
                        <DialogTitle className="text-center">No Company Registered</DialogTitle>
                        <DialogDescription className="text-center">
                            You need to register a company before you can access the dashboard. Register your company to start managing employees and payments.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="sm:justify-center">
                        <Button onClick={handleRegisterClick} className="w-full sm:w-auto">
                            <Building2 className="h-4 w-4 mr-2" />
                            Register Company
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
