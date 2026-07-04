import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { ReactNode } from 'react';
import type { ContentItem } from '../types/library.types';

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  locationState: {} as { editingContent?: ContentItem },
  editorState: {
    formData: {
      title: '',
      shortDescription: '',
      category: '',
      content: '',
      newCategory: ''
    },
    errors: {},
    imagePreview: '',
    showNewCategory: false,
    categoriesState: [],
    isCreatingCategory: false,
    isSaving: false,
    canSave: true,
    missing: [] as string[],
    isEditMode: false,
    fileInputRef: { current: null },
    contentRef: { current: null },
    isLeaveDialogOpen: false,
    setIsLeaveDialogOpen: vi.fn(),
    newCategoryError: '',
    sources: [''],
    setErrors: vi.fn(),
    setShowNewCategory: vi.fn(),
    setNewCategoryError: vi.fn(),
    updateForm: vi.fn(),
    handleCreateCategoryNow: vi.fn(),
    handleImageUpload: vi.fn(),
    removeImage: vi.fn(),
    addSource: vi.fn(),
    updateSource: vi.fn(),
    removeSource: vi.fn(),
    insertFormatting: vi.fn(),
    handleSave: vi.fn(),
    handleCancel: vi.fn(),
  },
  useContentEditor: vi.fn()
}));

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom');

  return {
    ...actual,
    useNavigate: () => mocks.navigate,
    useLocation: () => ({
      pathname: '/admin/library/add',
      state: mocks.locationState
    })
  };
});

vi.mock('../hooks/useContentEditor', () => ({
  useContentEditor: (props: unknown) => {
    mocks.useContentEditor(props);
    return mocks.editorState;
  }
}));

vi.mock('../components/ImageUploader', () => ({
  ImageUploader: () => <div>Image Uploader</div>
}));

vi.mock('../components/ContentForm', () => ({
  ContentForm: ({ categorySection }: { categorySection: ReactNode }) => (
    <div>
      <div>Content Form</div>
      {categorySection}
    </div>
  )
}));

vi.mock('../components/CategorySelector', () => ({
  CategorySelector: () => <div>Category Selector</div>
}));

vi.mock('../components/SourceList', () => ({
  SourceList: () => <div>Source List</div>
}));

vi.mock('../../../components/ui/confirm-action-dialog', () => ({
  ConfirmActionDialog: ({
    open,
    onConfirm
  }: {
    open: boolean;
    onConfirm: () => void;
  }) =>
    open ? (
      <div>
        <button type="button" onClick={onConfirm}>
          Confirm Leave
        </button>
      </div>
    ) : null
}));

import { AddContentScreen } from './AddContentPage';

describe('AddContentScreen', () => {
  beforeEach(() => {
    mocks.navigate.mockReset();
    mocks.useContentEditor.mockReset();
    mocks.locationState = {};
    mocks.editorState = {
      formData: {
        title: '',
        shortDescription: '',
        category: '',
        content: '',
        newCategory: ''
      },
      errors: {},
      imagePreview: '',
      showNewCategory: false,
      categoriesState: [],
      isCreatingCategory: false,
      isSaving: false,
      canSave: true,
      missing: [],
      isEditMode: false,
      fileInputRef: { current: null },
      contentRef: { current: null },
      isLeaveDialogOpen: false,
      setIsLeaveDialogOpen: vi.fn(),
      newCategoryError: '',
      sources: [''],
      setErrors: vi.fn(),
      setShowNewCategory: vi.fn(),
      setNewCategoryError: vi.fn(),
      updateForm: vi.fn(),
      handleCreateCategoryNow: vi.fn(),
      handleImageUpload: vi.fn(),
      removeImage: vi.fn(),
      addSource: vi.fn(),
      updateSource: vi.fn(),
      removeSource: vi.fn(),
      insertFormatting: vi.fn(),
      handleSave: vi.fn().mockResolvedValue(true),
      handleCancel: vi.fn().mockReturnValue(true),
    };
  });

  it('reads editing content from the route state and renders edit mode labels', () => {
    const editingContent: ContentItem = {
      id: 'content-1',
      title: 'مقال',
      shortDescription: 'ملخص',
      category: 'الأمراض',
      content: 'محتوى'
    };
    mocks.locationState = { editingContent };
    mocks.editorState.isEditMode = true;

    render(<AddContentScreen />);

    expect(screen.getByText('تحرير المحتوى')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'حفظ التغييرات' })).toBeInTheDocument();
    expect(mocks.useContentEditor).toHaveBeenCalledWith(
      expect.objectContaining({
        editingContent
      })
    );
  });

  it('navigates back to the library after a successful save', async () => {
    render(<AddContentScreen />);

    fireEvent.click(screen.getByRole('button', { name: 'حفظ المحتوى' }));

    expect(mocks.editorState.handleSave).toHaveBeenCalledTimes(1);
    await waitFor(() => {
      expect(mocks.navigate).toHaveBeenCalledWith('/admin/library');
    });
  });

  it('does not navigate after a failed save attempt', async () => {
    mocks.editorState.handleSave = vi.fn().mockResolvedValue(false);

    render(<AddContentScreen />);

    fireEvent.click(screen.getByRole('button', { name: 'حفظ المحتوى' }));

    expect(mocks.editorState.handleSave).toHaveBeenCalledTimes(1);
    await waitFor(() => {
      expect(mocks.navigate).not.toHaveBeenCalled();
    });
  });

  it('navigates immediately on cancel when the editor can leave safely', () => {
    render(<AddContentScreen />);

    fireEvent.click(screen.getByRole('button', { name: 'إلغاء' }));

    expect(mocks.editorState.handleCancel).toHaveBeenCalledTimes(1);
    expect(mocks.navigate).toHaveBeenCalledWith('/admin/library');
  });

  it('confirms leaving when the unsaved-changes dialog is open', () => {
    mocks.editorState.handleCancel = vi.fn().mockReturnValue(false);
    mocks.editorState.isLeaveDialogOpen = true;

    render(<AddContentScreen />);

    fireEvent.click(screen.getByRole('button', { name: 'العودة' }));
    expect(mocks.editorState.handleCancel).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getByRole('button', { name: 'Confirm Leave' }));

    expect(mocks.editorState.setIsLeaveDialogOpen).toHaveBeenCalledWith(false);
    expect(mocks.navigate).toHaveBeenCalledWith('/admin/library');
  });

  it('shows missing requirements and disables save when the form cannot be saved yet', () => {
    mocks.editorState.canSave = false;
    mocks.editorState.missing = ['العنوان مطلوب', 'الصورة مطلوبة'];

    render(<AddContentScreen />);

    expect(screen.getByText('• العنوان مطلوب')).toBeInTheDocument();
    expect(screen.getByText('• الصورة مطلوبة')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'حفظ المحتوى' })).toBeDisabled();
  });

  it('shows the saving label and spinner while the item is being saved', () => {
    mocks.editorState.isSaving = true;

    const { container } = render(<AddContentScreen />);

    expect(screen.getByRole('button', { name: 'جاري الحفظ...' })).toBeDisabled();
    expect(container.querySelector('.animate-spin')).not.toBeNull();
  });

  it('prioritizes category creation state over the normal save label', () => {
    mocks.editorState.isSaving = true;
    mocks.editorState.isCreatingCategory = true;

    const { container } = render(<AddContentScreen />);

    expect(screen.getByRole('button', { name: 'إنشاء الفئة...' })).toBeDisabled();
    expect(container.querySelector('.animate-spin')).not.toBeNull();
  });
});
