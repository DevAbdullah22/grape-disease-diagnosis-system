import { Card, CardContent, CardHeader, CardTitle } from "../../../components/ui/card";
import { Button } from "../../../components/ui/button";
import { X } from "lucide-react";

interface ConfirmModalState {
  open: boolean;
  title?: string;
  description?: string;
  onConfirm?: () => Promise<void> | void;
  requiredConfirmText?: string;
}

interface DeleteTreatmentDialogProps {
  confirmModal: ConfirmModalState;
  setConfirmModal: React.Dispatch<React.SetStateAction<ConfirmModalState>>;
  confirmInput: string;
  setConfirmInput: React.Dispatch<React.SetStateAction<string>>;
  addToast: (type: "success" | "error" | "warning", message: string) => void;
}

export function DeleteTreatmentDialog({
  confirmModal,
  setConfirmModal,
  confirmInput,
  setConfirmInput,
  addToast
}: DeleteTreatmentDialogProps) {
  if (!confirmModal.open) return null;

  const requiresTyping = !!confirmModal.requiredConfirmText;
  const confirmMatches =
    !requiresTyping ||
    confirmInput.trim().toLowerCase() ===
      (confirmModal.requiredConfirmText || "").trim().toLowerCase();

  return (
    <div className="fixed inset-0 bg-black/60 z-[100000] flex items-center justify-center p-4">
      <Card className="w-full max-w-lg bg-white dark:bg-slate-800">
        <CardHeader className="border-b">
          <div className="flex items-center justify-between">
            <CardTitle>{confirmModal.title}</CardTitle>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setConfirmInput("");
                setConfirmModal({ open: false });
              }}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-6 space-y-4">
          <div className="space-y-2">
            <p className="text-sm text-gray-700">{confirmModal.description}</p>
            {requiresTyping && (
              <div>
                <p className="text-sm text-gray-700">
                  للمتابعة، اكتب اسم الخطة{" "}
                  <span className="font-semibold">
                    "{confirmModal.requiredConfirmText}"
                  </span>{" "}
                  في الحقل أدناه للتأكيد:
                </p>
                <input
                  value={confirmInput}
                  onChange={(e) => setConfirmInput(e.target.value)}
                  placeholder="اكتب اسم الخطة للتأكيد"
                  className="mt-2 w-full px-3 py-2 border rounded-lg"
                />
                <p className="text-xs text-gray-500 mt-1">
                  المطابقة غير حساسة لحالة الأحرف.
                </p>
              </div>
            )}
          </div>

          <div className="flex gap-3 justify-end">
            <Button
              variant="outline"
              onClick={() => {
                setConfirmInput("");
                setConfirmModal({ open: false });
              }}
            >
              إلغاء
            </Button>
            <Button
              disabled={!confirmMatches}
              className={`bg-red-600 hover:bg-red-700 ${!confirmMatches ? "opacity-50 cursor-not-allowed" : ""}`}
              onClick={async () => {
                try {
                  await confirmModal.onConfirm?.();
                } catch (err) {
                  console.error(err);
                  addToast("error", "حدث خطأ أثناء العملية");
                } finally {
                  setConfirmInput("");
                  setConfirmModal({ open: false });
                }
              }}
            >
              تأكيد
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
