import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import {
  BenchPermissionsPayload,
  BenchRole,
  OnlinePlayer,
  closeBenchPermissions,
  selectBenchPermissions,
  setBenchPermissions,
} from '../../store/benchPermissions';
import { Locale, subscribeLocale } from '../../store/locale';
import useNuiEvent from '../../hooks/useNuiEvent';
import { fetchNui } from '../../utils/fetchNui';

type NuiResponse = {
  success: boolean;
  data?: BenchPermissionsPayload;
  error?: string;
};

const defaultPermissions = { use: true, move: false, pack: false, manage: false };

const BenchPermissionsModal: React.FC = () => {
  const dispatch = useAppDispatch();
  const state = useAppSelector(selectBenchPermissions);

  const [selectedRoleId, setSelectedRoleId] = useState<number | null>(null);
  const [roleName, setRoleName] = useState('');
  const [permissionFlags, setPermissionFlags] = useState(defaultPermissions);
  const [newMemberIdentifier, setNewMemberIdentifier] = useState('');
  const [selectedOnlinePlayer, setSelectedOnlinePlayer] = useState('');
  const [transferTarget, setTransferTarget] = useState('');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [deletePending, setDeletePending] = useState(false);
  // local state to force re-render when Locale is populated/updated
  const [, setLocaleVersion] = useState(0);

  // helper that returns Locale[key] if it's a real translation, otherwise the provided fallback
  const L = useCallback((key: string, fallback: string) => {
    const v = (Locale as any)[key];
    return v && v !== key ? (v as string) : fallback;
  }, []);

  

  useNuiEvent<BenchPermissionsPayload>('openBenchPermissions', (payload) => {
    if (payload) {
      dispatch(setBenchPermissions(payload));
    }
  });

  const formatMembersCount = useCallback((count: number) => {
    const template = L('crafting_permissions_members_count', '{count} members');
    return template.replace('{count}', String(count));
  }, [L]);

  const closeModal = useCallback(() => {
    fetchNui('benchPermissions:close');
    dispatch(closeBenchPermissions());
    setSelectedRoleId(null);
    setRoleName('');
    setPermissionFlags(defaultPermissions);
    setNewMemberIdentifier('');
    setSelectedOnlinePlayer('');
    setTransferTarget('');
    setErrorMessage(null);
    setDeletePending(false);
  }, [dispatch]);

  useEffect(() => {
    if (!state.open) {
      setSelectedRoleId(null);
      setRoleName('');
      setPermissionFlags(defaultPermissions);
      setNewMemberIdentifier('');
      setSelectedOnlinePlayer('');
      setTransferTarget('');
      setErrorMessage(null);
      setDeletePending(false);
      return;
    }

    if (state.roles.length === 0) {
      setSelectedRoleId(null);
      return;
    }

    setSelectedRoleId((prev) => {
      if (!prev) return state.roles[0].id;
      const exists = state.roles.find((role) => role.id === prev);
      return exists ? prev : state.roles[0].id;
    });
  }, [state.open, state.roles]);

  useEffect(() => {
    // subscribe to locale changes so translated strings update when App sets Locale
    const unsub = subscribeLocale(() => setLocaleVersion((v) => v + 1));
    return unsub;
  }, []);

  

  useEffect(() => {
    if (!state.open) return;
    if (!selectedRoleId) {
      setRoleName('');
      setPermissionFlags(defaultPermissions);
      setDeletePending(false);
      return;
    }

    const role = state.roles.find((entry) => entry.id === selectedRoleId);
    if (!role) {
      setRoleName('');
      setPermissionFlags(defaultPermissions);
      setDeletePending(false);
      return;
    }

    setRoleName(role.name);
    setPermissionFlags({
      use: role.canUse,
      move: role.canMove,
      pack: role.canPack,
      manage: role.canManage,
    });
    setDeletePending(false);
  }, [state.open, state.roles, selectedRoleId]);

  useEffect(() => {
    setDeletePending(false);
  }, [selectedRoleId]);

  useEffect(() => {
    if (!state.open) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        closeModal();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [state.open, closeModal]);

  const selectedRole: BenchRole | null = useMemo(
    () => (selectedRoleId ? state.roles.find((role) => role.id === selectedRoleId) ?? null : null),
    [state.roles, selectedRoleId]
  );

  const unassignedOnlinePlayers = useMemo(() => {
    if (!selectedRoleId) return state.onlinePlayers;
    return state.onlinePlayers.filter((player) => player.roleId !== selectedRoleId);
  }, [state.onlinePlayers, selectedRoleId]);

  const handleResponse = useCallback(
    (response?: NuiResponse) => {
      if (!response) return;
      if (response.success && response.data) {
        dispatch(setBenchPermissions(response.data));
        setDeletePending(false);
        setErrorMessage(null);
      } else if (response.error) {
        // dynamic key from server; fall back to the raw error string if not found in Locale
        setErrorMessage(
          ((Locale as any)[response.error] as string) || response.error || L('crafting_no_permission', 'You do not have permission')
        );
      } else {
        setErrorMessage(L('crafting_no_permission', 'You do not have permission'));
      }
    },
    [L, dispatch]
  );

  const sendAction = useCallback(
    async (event: string, payload: Record<string, unknown>) => {
      try {
        setErrorMessage(null);
        const response = await fetchNui<NuiResponse>(event, payload);
        handleResponse(response);
      } catch (error) {
        setErrorMessage(L('crafting_no_permission', 'You do not have permission'));
      }
    },
    [L, handleResponse]
  );

  const handleSaveRole = useCallback(() => {
    if (!state.benchId || !selectedRoleId) return;

    sendAction('benchPermissions:updateRole', {
      benchId: state.benchId,
      roleId: selectedRoleId,
      name: roleName.trim(),
      permissions: {
        use: permissionFlags.use,
        move: permissionFlags.move,
        pack: permissionFlags.pack,
        manage: permissionFlags.manage,
      },
    });
  }, [permissionFlags, roleName, selectedRoleId, sendAction, state.benchId]);

  const handleDeleteRole = useCallback(() => {
    if (!state.benchId || !selectedRoleId || !selectedRole) return;
    if (selectedRole.memberCount > 0) {
      setErrorMessage(L('crafting_role_has_members', 'Role has members'));
      setDeletePending(false);
      return;
    }

    if (!deletePending) {
      setDeletePending(true);
      setErrorMessage(L('crafting_permissions_confirm_delete', 'Delete this role?'));
      return;
    }

    sendAction('benchPermissions:deleteRole', {
      benchId: state.benchId,
      roleId: selectedRoleId,
    });
    setDeletePending(false);
  }, [L, deletePending, selectedRole, selectedRoleId, sendAction, state.benchId]);

  const handleCancelDelete = useCallback(() => {
    setDeletePending(false);
    setErrorMessage(null);
  }, []);

  const handleCreateRole = useCallback(() => {
    if (!state.benchId) return;

    const defaultLabel = L('crafting_role_new', 'New role');

    sendAction('benchPermissions:createRole', {
      benchId: state.benchId,
      name: defaultLabel,
      permissions: defaultPermissions,
    });
  }, [L, sendAction, state.benchId]);

  const handleAddMember = useCallback(() => {
    if (!state.benchId || !selectedRoleId) return;
    const target = (selectedOnlinePlayer || newMemberIdentifier).trim();
    if (!target) {
      setErrorMessage(L('crafting_permissions_identifier_required', 'Identifier required'));
      return;
    }

    sendAction('benchPermissions:setMemberRole', {
      benchId: state.benchId,
      roleId: selectedRoleId,
      target,
    });
    setNewMemberIdentifier('');
    setSelectedOnlinePlayer('');
  }, [L, newMemberIdentifier, selectedOnlinePlayer, selectedRoleId, sendAction, state.benchId]);

  const handleRemoveMember = useCallback(
    (identifier: string) => {
      if (!state.benchId) return;
      sendAction('benchPermissions:setMemberRole', {
        benchId: state.benchId,
        target: identifier,
      });
    },
    [sendAction, state.benchId]
  );

  const handleTransferOwnership = useCallback(() => {
    if (!state.benchId) return;
    const target = (transferTarget || newMemberIdentifier || selectedOnlinePlayer).trim();
    if (!target) {
      setErrorMessage(L('crafting_permissions_identifier_required', 'Identifier required'));
      return;
    }

    sendAction('benchPermissions:transferOwnership', {
      benchId: state.benchId,
      target,
    });
    setTransferTarget('');
  }, [L, newMemberIdentifier, selectedOnlinePlayer, sendAction, state.benchId, transferTarget]);

  if (!state.open) {
    return null;
  }

  const permissionList = [
    { key: 'use' as const, label: L('crafting_permission_use', 'Use') },
    { key: 'move' as const, label: L('crafting_permission_move', 'Move') },
    { key: 'pack' as const, label: L('crafting_permission_pack', 'Pack') },
    { key: 'manage' as const, label: L('crafting_permission_manage', 'Manage') },
  ];

  return (
    <div className="bench-permissions-overlay">
      <div className="bench-permissions-modal">
        <header className="bench-permissions-header">
          <div>
            <h2>{L('crafting_permissions_title', 'Bench Permissions')}</h2>
            <p className="bench-permissions-subtitle">
              {state.benchLabel || state.benchId}
            </p>
          </div>
          <button className="bench-permissions-close" onClick={closeModal}>
            {L('crafting_permissions_close', 'Close')}
          </button>
        </header>
        <section className="bench-permissions-owner">
          <strong>{L('crafting_permissions_owner', 'Owner')}:</strong>{' '}
          <span>
            {state.owner?.name || L('crafting_permissions_unknown', 'Unknown')}
            {state.owner?.online ? L('crafting_permissions_status_online', 'Online') : L('crafting_permissions_status_offline', 'Offline')}
          </span>
        </section>

        {errorMessage && <div className="bench-permissions-error">{errorMessage}</div>}

        <div className="bench-permissions-body">
          <aside className="bench-permissions-sidebar">
            <div className="bench-permissions-sidebar-header">
        <h3>{L('crafting_permissions_roles', 'Roles')}</h3>
        <button className="bench-permissions-add" onClick={handleCreateRole}>
          {L('crafting_permissions_add_role', 'Add role')}
        </button>
            </div>

            <div className="bench-permissions-role-list">
              {state.roles.map((role) => (
                <button
                  key={role.id}
                  onClick={() => setSelectedRoleId(role.id)}
                  className={role.id === selectedRoleId ? 'active' : ''}
                >
                  <span>{role.name}</span>
                  <small>{formatMembersCount(role.memberCount)}</small>
                </button>
              ))}
              {state.roles.length === 0 && (
                <div className="bench-permissions-empty">{L('crafting_permissions_no_roles', 'No roles')}</div>
              )}
            </div>
          </aside>

          <section className="bench-permissions-content">
            {selectedRole ? (
              <>
                <div className="bench-permissions-role-details">
                  <label>
                    {L('crafting_permissions_role_name', 'Role name')}
                    <input
                      type="text"
                      value={roleName}
                      onChange={(event) => setRoleName(event.target.value)}
                    />
                  </label>
                  <div className="bench-permissions-permission-grid">
                    {permissionList.map((item) => (
                      <label key={item.key} className="permission-toggle">
                        <input
                          type="checkbox"
                          checked={permissionFlags[item.key]}
                          onChange={(event) =>
                            setPermissionFlags((prev) => ({ ...prev, [item.key]: event.target.checked }))
                          }
                        />
                        <span>{item.label}</span>
                      </label>
                    ))}
                  </div>
                  <div className="bench-permissions-role-actions">
                    <button onClick={handleSaveRole}>{L('crafting_permissions_save_role', 'Save role')}</button>
                    <button
                      onClick={handleDeleteRole}
                      disabled={selectedRole.memberCount > 0}
                      className={deletePending ? 'danger confirm' : 'danger'}
                    >
                      {deletePending
                        ? L('crafting_permissions_confirm_delete', 'Confirm delete')
                        : L('crafting_permissions_delete_role', 'Delete role')}
                    </button>
                    {deletePending && (
                      <button onClick={handleCancelDelete} className="secondary">
                        {L('crafting_permissions_close', 'Cancel')}
                      </button>
                    )}
                  </div>
                </div>

                <div className="bench-permissions-members">
                  <h4>{L('crafting_permissions_members', 'Members')}</h4>
                  {selectedRole.members.length === 0 ? (
                    <div className="bench-permissions-empty">{L('crafting_permissions_no_members', 'No members')}</div>
                  ) : (
                    <ul>
                      {selectedRole.members.map((member) => (
                        <li key={member.identifier}>
                          <div>
                            <strong>{member.name}</strong>
                            <small>{member.identifier}</small>
                          </div>
                          <div className="bench-permissions-member-actions">
                            <span className={member.online ? 'online' : 'offline'}>
                              {member.online
                                ? L('crafting_permissions_status_online', 'Online')
                                : L('crafting_permissions_status_offline', 'Offline')}
                            </span>
                            <button onClick={() => handleRemoveMember(member.identifier)}>
                              {L('crafting_permissions_remove', 'Remove')}
                            </button>
                          </div>
                        </li>
                      ))}
                    </ul>
                  )}

                  <div className="bench-permissions-add-member">
                    <h5>{L('crafting_permissions_add_member', 'Add member')}</h5>
                    <div className="select-wrapper">
                      <select
                        className="bench-permissions-select"
                        value={selectedOnlinePlayer}
                        onChange={(event) => {
                          setSelectedOnlinePlayer(event.target.value);
                          setNewMemberIdentifier(event.target.value);
                        }}
                      >
                        <option value="">{L('crafting_permissions_select_player', 'Select player')}</option>
                        {unassignedOnlinePlayers.map((player: OnlinePlayer) => (
                          <option key={player.identifier} value={player.identifier}>
                            {player.name} {player.roleId ? `(${L('crafting_permissions_assigned', 'assigned')})` : ''}
                          </option>
                        ))}
                      </select>
                    </div>

                    <input
                      type="text"
                      value={newMemberIdentifier}
                      placeholder={L('crafting_permissions_identifier', 'Identifier')}
                      onChange={(event) => setNewMemberIdentifier(event.target.value)}
                    />
                    <button onClick={handleAddMember}>{L('crafting_permissions_assign', 'Assign')}</button>
                  </div>
                </div>
              </>
            ) : (
              <div className="bench-permissions-empty-panel">
                {L('crafting_permissions_no_role_selected', 'No role selected')}
              </div>
            )}
          </section>
        </div>

        <footer className="bench-permissions-footer">
          <div className="bench-permissions-transfer">
            <h4>{L('crafting_permissions_transfer', 'Transfer')}</h4>
            <input
              type="text"
              value={transferTarget}
              placeholder={L('crafting_permissions_identifier', 'Identifier')}
              onChange={(event) => setTransferTarget(event.target.value)}
            />
            <button onClick={handleTransferOwnership} disabled={!state.canTransfer}>
              {L('crafting_permissions_transfer_button', 'Transfer')}
            </button>
          </div>
        </footer>
      </div>
    </div>
  );
};

export default BenchPermissionsModal;


